require "semantic_version"

@[Athena::Console::Annotations::AsCommand("|_complete", description: "Internal command to provide shell completion suggestions")]
# :nodoc:
class Athena::Console::Commands::Complete < Athena::Console::Command
  API_VERSION = 2

  @completion_outputs : Hash(String, ACON::Completion::Output::Interface.class)

  @debug : Bool = false

  def initialize(completion_outputs : Hash(String, ACON::Completion::Output::Interface.class) = Hash(String, ACON::Completion::Output::Interface.class).new)
    @completion_outputs = completion_outputs.merge!({
      "bash" => ACON::Completion::Output::Bash,
      "fish" => ACON::Completion::Output::Fish,
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
      raise ACON::Exception::Runtime.new "The '--shell' option must be set."
    end

    unless completion_output = @completion_outputs[shell]?
      raise ACON::Exception::Runtime.new %(Shell completion is not supported for your shell: '#{shell}' (supported: '#{@completion_outputs.keys.join "', '"}').)
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
    node = command

    if node.nil? && (first_argument = completion_input.first_argument)
      begin
        node = ACON::Commands::Group.new first_argument
        node.application = self.application
      rescue ACON::Exception::InvalidArgument
        # The first argument is not a valid command name, nothing to walk.
      end
    end

    tree_suggested = false

    if node && (tree = self.complete_command_tree node, input, suggestions)
      if tree.is_a? Tuple
        command, completion_input = tree
      else
        tree_suggested = true
      end
    end

    if tree_suggested
      self.log "  Suggesting the sub-commands and options of a command tree level."
    elsif command.nil?
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
      raise ACON::Exception::Runtime.new "The '--current' option must be set and it must be an integer."
    end

    completion_input = ACON::Completion::Input.from_tokens input.option("input", Array(String)), index

    begin
      completion_input.bind self.application.definition
    rescue ex : ::Exception
      # TODO: Make this part of the `rescue` after Crystal 1.13
      raise ex unless ex.is_a? ACON::Exception
    end

    completion_input
  end

  # Completes an input that walks into the tree below the provided *command*.
  #
  # Returns `true` when suggestions for a branch level were added, a rebased command and input when the cursor sits at leaf level,
  # or `nil` when the regular completion flow applies.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  private def complete_command_tree(command : ACON::Command, input : ACON::Input::Interface, suggestions : ACON::Completion::Suggestions) : {ACON::Command, ACON::Completion::Input} | Bool | Nil
    application = self.application
    path = command.name

    return if application.commands(path).empty?

    words = input.option "input", Array(String)
    current = input.option("current", String).to_i
    tokens = words[0, current]
    cursor_word = words[current]? || ""

    return if tokens.empty?

    node = command
    is_root = true

    loop do
      definition = ACON::Input::Definition.new

      if node
        definition.options = node.native_definition.options.values
        definition << application.definition.options.values
      else
        definition.options = application.definition.options.values
      end

      if is_root
        definition.arguments = application.definition.arguments.values
      end

      definition.ignore_extra_arguments = true

      level_input = ACON::Input::ARGV.new tokens

      begin
        level_input.bind definition
      rescue ex : ::Exception
        # TODO: Make this part of the `rescue` after Crystal 1.13
        raise ex unless ex.is_a? ACON::Exception

        return
      end

      unparsed = level_input.unparsed_tokens
      consumed = tokens[0, tokens.size - unparsed.size]

      if "--" == consumed.last?
        # The remaining tokens are the current node's own arguments.
        return if is_root

        return node ? self.rebase_completion(node, path, tokens, words, current) : true
      end

      if unparsed.empty?
        if cursor_word.starts_with? '-'
          suggestions.suggest_options definition.options.values

          return true
        end

        prefix_size = path.size + 1
        application.commands(path).keys.map(&.[prefix_size..].split(':').first).uniq!.each do |segment|
          child_path = "#{path}:#{segment}"
          suggestions.suggest_value segment, (application.has?(child_path) ? application.get(child_path).description : "")
        end

        return true if node.nil? || node.native_definition.arguments.empty?

        # The node's own argument values complete next to its sub-commands.
        return is_root ? nil : self.rebase_completion(node, path, tokens, words, current)
      end

      segment = unparsed.shift
      child_path = "#{path}:#{segment}"

      # An alias of the current node is not a sub-command.
      if registered = application.has?(child_path) && application.get(child_path).name != path
        child_path = application.get(child_path).name
      end

      has_descendants = !application.commands(child_path).empty?

      if !registered && !has_descendants
        # The segment names no sub-command: it starts the node's own arguments, if it has any.
        return true if node.nil? || node.native_definition.arguments.empty?

        return is_root ? nil : self.rebase_completion(node, path, tokens, words, current)
      end

      if registered && !has_descendants
        return self.rebase_completion application.get(child_path), child_path, unparsed, words, current
      end

      node = registered ? application.get(child_path) : nil
      path = child_path
      tokens = unparsed
      is_root = false
    end
  end

  # Rebases the completion input on a tree node, so that its own definition completes the remaining words.
  private def rebase_completion(node : ACON::Command, path : String, tokens : Array(String), words : Array(String), current : Int32) : {ACON::Command, ACON::Completion::Input}
    {
      node.is_a?(ACON::Commands::Lazy) ? node.command : node,
      ACON::Completion::Input.from_tokens([path].concat(tokens).concat(words[current..]), 1 + tokens.size),
    }
  end

  private def find_command(completion_input : ACON::Completion::Input, output : ACON::Output::Interface) : ACON::Command?
    begin
      unless input_name = completion_input.first_argument
        return nil
      end

      return self.application.find input_name
    rescue ACON::Exception::CommandNotFound
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
      "#{messages.join(EOL)}#{EOL}",
      mode: "a"
    )
  end
end
