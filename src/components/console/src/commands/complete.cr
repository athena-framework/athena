require "semantic_version"

@[Athena::Console::Annotations::AsCommand("|_complete", description: "Internal command to provide shell completion suggestions")]
class Athena::Console::Commands::Complete < Athena::Console::Command
  COMPLETION_API_VERSION = 1

  @completion_outputs : Hash(String, ACON::Completion::OutputInterface.class)

  @debug : Bool = false

  def initialize(completion_outputs : Hash(String, ACON::Completion::OutputInterface.class) = Hash(String, ACON::Completion::OutputInterface.class).new)
    @completion_outputs = completion_outputs.merge!({
      "bash" => ACON::Completion::Output::Bash,
    } of String => ACON::Completion::OutputInterface.class)

    super()
  end

  protected def configure : Nil
    self
      .definition(
        ACON::Input::Option.new("shell", "s", :required, "The shell type ('#{@completion_outputs.keys.join "', '"}')"),
        ACON::Input::Option.new("input", "i", ACON::Input::Option::Value[:required, :is_array], "An array of input tokens (e.g. COMP_WORDS or argv)"),
        ACON::Input::Option.new("current", "c", :required, "The index of the 'input' array that the cursor is in (e.g. COMP_CWORD)"),
        ACON::Input::Option.new("api-version", "a", :required, "The API version of the completion script")
      )
  end

  protected def setup(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
    @debug = ENV["ATHENA_DEBUG_COMPLETION"]? == "true"
    @debug = true
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if (major_version = input.option("api-version"))
      version = SemanticVersion.new major_version.to_i, 0, 0

      if version < SemanticVersion.new(COMPLETION_API_VERSION, 0, 0)
        message = "Completion script version is not supported ('#{version.major}' given, >=#{COMPLETION_API_VERSION} required)."

        self.log message

        output.puts "#{message} Install the Athena completion script again byusing the 'completion' command."

        return ACON::Command::Status.new 126
      end
    end

    unless shell = input.option "shell"
      raise ACON::Exceptions::RuntimeError.new "The '--shell' option must be set."
    end

    unless completion_output = @completion_outputs[shell]?
      raise ACON::Exceptions::RuntimeError.new %(Shell completion is not supported for your shell: '#{shell}' (supported: '#{@completion_outputs.keys.join "', '"}'))
    end

    completion_input = self.create_completion_input input
    suggestions = ACON::Completion::Suggestions.new

    self.log({
      "",
      "<comment>#{Time.local}</>",
      "<info>Input:</> <comment>(\"|\" indicates the cursor position)</>",
      " #{completion_input}",
      "<info>Command:</>",
      " #{ARGV.join " "}",
      "<info>Messages:</>",
    })

    command = self.find_command completion_input, output

    if command.nil?
      self.log "  No command found, completing using the Application class."

      self.application.complete completion_input, suggestions
    end

    completion_output = completion_output.new

    self.log "<info>Suggestions:</>"

    completion_output.write suggestions, output

    ACON::Command::Status::SUCCESS
  end

  private def create_completion_input(input : ACON::Input::Interface) : ACON::Completion::Input
    current_index = input.option "current"

    if current_index.nil? || !(index = current_index.to_i?)
      raise ACON::Exceptions::RuntimeError.new "The '--current' option must be set and it must be an integer."
    end

    completion_input = ACON::Completion::Input.from_tokens input.option("input", Array(String)), index

    begin
      completion_input.bind self.application.definition
    rescue ex : ACON::Exceptions::ConsoleException
    end

    completion_input
  end

  private def find_command(completion_input : ACON::Completion::Input, output : ACON::Output::Interface) : ACON::Command?
    begin
      unless input_name = completion_input.first_argument
        return nil
      end

      return self.application.find input_name
    rescue ex : ACON::Exceptions::CommandNotFound
      # noop
    end

    nil
  end

  private def log(messages : String | Enumerable(String)) : Nil
    return unless @debug

    messages = messages.is_a?(String) ? {messages} : messages

    command_name = Path.new(PROGRAM_NAME).basename
    File.write(
      "#{Dir.tempdir}/athena_#{command_name}.log",
      "#{messages.join(ACON::System::EOL)}#{ACON::System::EOL}",
      mode: "a"
    )
  end
end
