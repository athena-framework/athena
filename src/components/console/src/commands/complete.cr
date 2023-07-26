require "semantic_version"

@[Athena::Console::Annotations::AsCommand("|_complete", description: "Internal command to provide shell completion suggestions")]
# :nodoc:
class Athena::Console::Commands::Complete < Athena::Console::Command
  API_VERSION = 1

  @completion_outputs : Hash(String, ACON::Completion::Output::Interface.class)

  @debug : Bool = false

  def initialize(completion_outputs : Hash(String, ACON::Completion::Output::Interface.class) = Hash(String, ACON::Completion::Output::Interface.class).new)
    @completion_outputs = completion_outputs.merge!({
      "bash" => ACON::Completion::Output::Bash,
      "zsh"  => ACON::Completion::Output::Zsh,
    } of String => ACON::Completion::Output::Interface.class)

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
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if major_version = input.option("api-version")
      version = SemanticVersion.new major_version.to_i, 0, 0

      if version < SemanticVersion.new(API_VERSION, 0, 0)
        message = "Completion script version is not supported ('#{version.major}' given, >=#{API_VERSION} required)."

        self.log message

        output.puts "#{message} Install the Athena completion script again by using the 'completion' command."

        return ACON::Command::Status.new 126
      end
    end

    unless shell = input.option "shell"
      raise ACON::Exceptions::RuntimeError.new "The '--shell' option must be set."
    end

    unless completion_output = @completion_outputs[shell]?
      raise ACON::Exceptions::RuntimeError.new %(Shell completion is not supported for your shell: '#{shell}' (supported: '#{@completion_outputs.keys.join "', '"}').)
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
    elsif completion_input.must_suggest_argument_values_for?("command") &&
          command.name != completion_input.completion_value &&
          !command.aliases.includes?(completion_input.completion_value)
      self.log "  Found command, suggesting aliases"

      # expand shortcut names ("foo:f<TAB>") into their full name ("foo:foo")
      suggestions.suggest_values [command.name].concat(command.aliases)
    else
      command.merge_application_definition
      completion_input.bind command.definition

      if completion_input.completion_type.option_name?
        self.log "  Completing option names for the <comment>#{command.is_a?(ACON::Commands::Lazy) ? command.command.class : command.class}</> command."

        suggestions.suggest_options command.definition.options.values
      else
        self.log({
          "  Completing using the <comment>#{command.is_a?(ACON::Commands::Lazy) ? command.command.class : command.class}</> class.",
          "  Completing <comment>#{completion_input.completion_type}</> for <comment>#{completion_input.completion_name}</>",
        })

        command.complete completion_input, suggestions
      end
    end

    completion_output = completion_output.new

    self.log "<info>Suggestions:</>"

    if (options = suggestions.suggested_options) && !options.empty?
      self.log %(  --#{options.map(&.name).join(" --")})
    elsif (values = suggestions.suggested_values) && !values.empty?
      self.log %(  #{values.join(" ")})
    else
      self.log "  <comment>No suggestions were provided</>"
    end

    completion_output.write suggestions, output

    ACON::Command::Status::SUCCESS
  rescue ex : ::Exception
    self.log({"<error>Error!</>", ex.to_s})

    raise ex if output.verbosity.debug?

    ACON::Command::Status::INVALID
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
