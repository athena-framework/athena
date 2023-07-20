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

  private def log(messages : String | Enumerable(String)) : Nil
    return unless @debug

    messages = messages.is_a?(String) ? {messages} : messages

    pp messages
  end
end
