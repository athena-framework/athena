require "levenshtein"

# A container for a collection of multiple `ACON::Command`, and serves as the entry point of a CLI application.
# This class is optimized for a standard CLI environment; but it may be subclassed to provide a more specialized/customized entry point.
#
# ## Default Command
#
# The default command represents which command should be executed when no command name is provided; by default this is `ACON::Commands::List`.
# For example, running `./console` would result in all the available commands being listed.
# The default command can be customized via `#default_command`.
#
# ## Single Command Applications
#
# In some cases a CLI may only have one supported command in which passing the command's name each time is tedious.
# In such a case an application may be declared as a single command application via the optional second argument to `#default_command`.
# Passing `true` makes it so that any supplied arguments or options are passed to the default command.
#
# WARNING: Arguments and options passed to the default command are ignored when `#single_command?` is `false`.
#
# ## Custom Applications
#
# `ACON::Application` may also be extended in order to better fit a given application.
# For example, it could define some [global custom styles][Athena::Console::Formatter::OutputStyleInterface--global-custom-styles],
# override the array of default commands, or customize the default input options, etc.
class Athena::Console::Application
  # Returns the version of this CLI application.
  getter version : String

  # Returns the name of this CLI application.
  getter name : String

  # By default, the application will auto [exit](https://crystal-lang.org/api/toplevel.html#exit(status=0):NoReturn-class-method) after executing a command.
  # This method can be used to disable that functionality.
  #
  # If set to `false`, the `ACON::Command::Status` of the executed command is returned from `#run`.
  # Otherwise the `#run` method never returns.
  #
  # ```
  # application = ACON::Application.new "My CLI"
  # application.auto_exit = false
  # exit_status = application.run
  # exit_status # => ACON::Command::Status::SUCCESS
  #
  # application.auto_exit = true
  # exit_status = application.run
  #
  # # This line is never reached.
  # exit_status
  # ```
  setter auto_exit : Bool = true

  # By default, the application will gracefully handle exceptions raised as part of the execution of a command
  # by formatting and outputting it; including varying levels of information depending on the `ACON::Output::Verbosity` level used.
  #
  # If set to `false`, that logic is bypassed and the exception is bubbled up to where `#run` was invoked from.
  #
  # ```
  # application = ACON::Application.new "My CLI"
  #
  # application.register "foo" do |input, output, command|
  #   output.puts %(Hello #{input.argument "name"}!)
  #
  #   # Denote that this command has finished successfully.
  #   ACON::Command::Status::SUCCESS
  # end.argument("name", :required)
  #
  # application.default_command "foo", true
  # application.catch_exceptions = false
  #
  # application.run # => Not enough arguments (missing: 'name'). (Athena::Console::Exception::Runtime)
  # ```
  setter catch_exceptions : Bool = true

  # Allows setting the `ACON::Loader::Interface` that should be used by `self`.
  # See the related interface for more information.
  setter command_loader : ACON::Loader::Interface? = nil

  # When set to `true`, the application will check if `PROGRAM_NAME`'s basename matches a registered command.
  # If it does, `self` behaves as a [single command application](/Console/Application/#Athena::Console::Application--single-command-applications) for that command.
  #
  # This enables symlink-based command invocation, where `./command-name` (symlinked to the main binary) will automatically execute the `command-name` command.
  # Any arguments are passed to the matched command rather than being interpreted as a command name.
  property? use_program_name_as_command : Bool = false

  # Returns/sets the `ACON::Helper::HelperSet` associated with `self`.
  #
  # The default helper set includes:
  #
  # * `ACON::Helper::Formatter`
  # * `ACON::Helper::Question`
  property helper_set : ACON::Helper::HelperSet { self.default_helper_set }

  # Returns the commands resolved for the current invocation and their bound inputs, or `nil` if no command is running.
  # See [Sub-commands][Athena::Console::Command--sub-commands] for more information.
  getter command_chain : ACON::CommandChain? = nil

  @commands = Hash(String, ACON::Command).new
  @default_command : String = "list"
  @definition : ACON::Input::Definition? = nil
  @initialized : Bool = false
  @running_command : ACON::Command? = nil
  @single_command : Bool = false
  @terminal : ACON::Terminal

  def initialize(@name : String, @version : String = "UNKNOWN")
    @terminal = ACON::Terminal.new

    # TODO: Emit events when certain signals are triggered.
    # This will require the ability to optional set an event dispatcher on this type.
  end

  # Adds the provided *command* instance to `self`, allowing it be executed.
  def add(command : ACON::Command) : ACON::Command?
    self.init

    command.application = self

    unless command.enabled?
      command.application = nil

      return nil
    end

    if !command.is_a? ACON::Commands::Lazy
      command.definition
    end

    @commands[command.name] = command

    command.aliases.each do |a|
      @commands[a] = command
    end

    command
  end

  # Returns if application should exit automatically after executing a command.
  # See `#auto_exit=`.
  def auto_exit? : Bool
    @auto_exit
  end

  # Returns if the application should handle exceptions raised within the execution of a command.
  # See `#catch_exceptions=`.
  def catch_exceptions? : Bool
    @catch_exceptions
  end

  # Returns all commands within `self`, optionally only including the ones within the provided *namespace*.
  # The keys of the returned hash represent the full command names, while the values are the command instances.
  def commands(namespace : String? = nil) : Hash(String, ACON::Command)
    self.init

    if namespace.nil?
      unless command_loader = @command_loader
        return @commands
      end

      commands = @commands.dup
      command_loader.names.each do |name|
        if !commands.has_key?(name) && self.has?(name)
          commands[name] = self.get name
        end
      end

      return commands
    end

    commands = Hash(String, ACON::Command).new
    @commands.each do |name, command|
      if namespace == self.extract_namespace(name, namespace.count(':') + 1)
        commands[name] = command
      end
    end

    if command_loader = @command_loader
      command_loader.names.each do |name|
        if !commands.has_key?(name) && namespace == self.extract_namespace(name, namespace.count(':') + 1) && self.has?(name)
          commands[name] = self.get name
        end
      end
    end

    commands
  end

  # Sets the [default command][Athena::Console::Application--default-command] to the command with the provided *name*.
  #
  # For example, executing the following console script via `./console`
  # would result in `Hello world!` being printed instead of the default list output.
  #
  # ```
  # application = ACON::Application.new "My CLI"
  #
  # application.register "foo" do |_, output|
  #   output.puts "Hello world!"
  #   ACON::Command::Status::SUCCESS
  # end
  #
  # application.default_command "foo"
  #
  # application.run
  #
  # ./console # => Hello world!
  # ```
  #
  # For example, executing the following console script via `./console George`
  # would result in `Hello George!` being printed. If we tried this again without setting *single_command*
  # to `true`, it would error saying `Command 'George' is not defined.
  #
  # ```
  # application = ACON::Application.new "My CLI"
  #
  # application.register "foo" do |input, output, command|
  #   output.puts %(Hello #{input.argument "name"}!)
  #   ACON::Command::Status::SUCCESS
  # end.argument("name", :required)
  #
  # application.default_command "foo", true
  #
  # application.run
  # ```
  def default_command(name : String, single_command : Bool = false) : self
    @default_command = name

    if single_command
      self.find name

      @single_command = true
    end

    self
  end

  # Returns the `ACON::Input::Definition` associated with `self`.
  # See the related type for more information.
  def definition : ACON::Input::Definition
    @definition ||= self.default_input_definition

    if self.single_command?
      input_definition = @definition.not_nil!
      input_definition.arguments = Array(ACON::Input::Argument).new

      return input_definition
    end

    @definition.not_nil!
  end

  # Sets the *definition* that should be used by `self`.
  # See the related type for more information.
  def definition=(@definition : ACON::Input::Definition)
  end

  # Determines what values should be added to the possible *suggestions* based on the provided *input*.
  #
  # By default this handles completing commands and options, but can be overridden if needed.
  def complete(input : ACON::Completion::Input, suggestions : ACON::Completion::Suggestions) : Nil
    if input.completion_type.argument_value? && "command" == input.completion_name
      self.commands.each do |name, command|
        next if command.hidden? || command.name != name

        suggestions.suggest_value name, command.description

        command.aliases.each do |a|
          suggestions.suggest_value a, command.description
        end
      end

      return
    end

    if input.completion_type.option_name?
      suggestions.suggest_options self.definition.options.values

      return
    end
  end

  # Yields each command within `self`, optionally only yields those within the provided *namespace*.
  def each_command(namespace : String? = nil, & : ACON::Command -> Nil) : Nil
    self.commands(namespace).each_value { |c| yield c }
  end

  # Returns the `ACON::Command` with the provided *name*, which can either be the full name, an abbreviation, or an alias.
  # This method will attempt to find the best match given an abbreviation of a name or alias.
  #
  # Raises an `ACON::Exception::CommandNotFound` exception when the provided *name* is incorrect or ambiguous.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def find(name : String) : ACON::Command
    self.init

    aliases = Hash(String, String).new

    @commands.each_value do |command|
      command.aliases.each do |a|
        @commands[a] = command unless self.has? a
      end
    end

    return self.get name if self.has? name

    all_command_names = if command_loader = @command_loader
                          command_loader.names + @commands.keys
                        else
                          @commands.keys
                        end

    expression = "#{name.split(':').join("[^:]*:", &->Regex.escape(String))}[^:]*"
    commands = all_command_names.select(/^#{expression}/)

    if commands.empty?
      commands = all_command_names.select(/^#{expression}/i)
    end

    if commands.empty? || commands.select(/^#{expression}$/i).size < 1
      if pos = name.index ':'
        # Check if a namespace exists and contains commands
        self.find_namespace name[0...pos]
      end

      message = "Command '#{name}' is not defined."

      if (alternatives = self.find_alternatives name, all_command_names) && (!alternatives.empty?)
        alternatives.select! do |n|
          !self.get(n).hidden?
        end

        case alternatives.size
        when 1 then message += "\n\nDid you mean this?\n    "
        else        message += "\n\nDid you mean one of these?\n    "
        end

        message += alternatives.join("\n    ")
      end

      raise ACON::Exception::CommandNotFound.new message, alternatives
    end

    # Filter out aliases for commands which are already on the list.
    if commands.size > 1
      command_list = @commands.dup

      commands.select! do |name_or_alias|
        command = if !command_list.has_key?(name_or_alias)
                    command_list[name_or_alias] = @command_loader.not_nil!.get name_or_alias
                  else
                    command_list[name_or_alias]
                  end

        command_name = command.name

        aliases[name_or_alias] = command_name

        command_name == name_or_alias || !commands.includes? command_name
      end.uniq!

      usable_width = @terminal.width - 10
      max_len = commands.max_of &->ACON::Helper.width(String)
      abbreviations = commands.map do |n|
        if command_list[n].hidden?
          commands.delete n

          next nil
        end

        abbreviation = "#{n.rjust max_len, ' '} #{command_list[n].description}"

        ACON::Helper.width(abbreviation) > usable_width ? "#{abbreviation[0, usable_width - 3]}..." : abbreviation
      end

      if commands.size > 1
        suggestions = self.abbreviation_suggestions abbreviations.compact

        raise ACON::Exception::CommandNotFound.new "Command '#{name}' is ambiguous.\nDid you mean one of these?\n#{suggestions}", commands
      end
    end

    command = self.get commands.first

    raise ACON::Exception::CommandNotFound.new "The command '#{name}' does not exist." if command.hidden?

    command
  end

  # Returns the full name of a registered namespace with the provided *name*, which can either be the full name or an abbreviation.
  #
  # Raises an `ACON::Exception::NamespaceNotFound` exception when the provided *name* is incorrect or ambiguous.
  def find_namespace(name : String) : String
    all_namespace_names = self.namespaces

    expression = "#{name.split(':').join("[^:]*:", &->Regex.escape(String))}[^:]*"
    namespaces = all_namespace_names.select(/^#{expression}/)

    if namespaces.empty?
      message = "There are no commands defined in the '#{name}' namespace."

      if (alternatives = self.find_alternatives name, all_namespace_names) && (!alternatives.empty?)
        case alternatives.size
        when 1 then message += "\n\nDid you mean this?\n    "
        else        message += "\n\nDid you mean one of these?\n    "
        end

        message += alternatives.join("\n    ")
      end

      raise ACON::Exception::NamespaceNotFound.new message, alternatives
    end

    exact = namespaces.includes? name

    if namespaces.size > 1 && !exact
      raise ACON::Exception::NamespaceNotFound.new "The namespace '#{name}' is ambiguous.\nDid you mean one of these?\n#{self.abbreviation_suggestions namespaces}", namespaces
    end

    exact ? name : namespaces.first
  end

  # Returns the `ACON::Command` with the provided *name*.
  #
  # Raises an `ACON::Exception::CommandNotFound` exception when a command with the provided *name* does not exist.
  def get(name : String) : ACON::Command
    self.init

    raise ACON::Exception::CommandNotFound.new "The command '#{name}' does not exist." unless self.has? name

    if !@commands.has_key? name
      raise ACON::Exception::CommandNotFound.new "The '#{name}' command cannot be found because it is registered under multiple names. Make sure you don't set a different name via constructor or 'name='."
    end

    @commands[name]
  end

  # Returns `true` if a command with the provided *name* exists, otherwise `false`.
  def has?(name : String) : Bool
    self.init

    return true if @commands.has_key? name

    if (command_loader = @command_loader) && command_loader.has? name
      self.add command_loader.get name

      true
    else
      false
    end
  end

  # By default this is the same as `#long_version`, but can be overridden
  # to provide more in-depth help/usage instructions for `self`.
  def help : String
    self.long_version
  end

  # Returns all unique namespaces used by currently registered commands,
  # excluding the global namespace.
  def namespaces : Array(String)
    namespaces = [] of String

    self.commands.each_value do |command|
      next if command.hidden?

      namespaces.concat self.extract_all_namespaces command.name.not_nil!

      command.aliases.each do |a|
        namespaces.concat self.extract_all_namespaces a
      end
    end

    namespaces.reject!(&.blank?).uniq!
  end

  # Runs the current application, optionally with the provided *input* and *output*.
  #
  # Returns the `ACON::Command::Status` of the related command execution if `#auto_exit?` is `false`.
  # Will gracefully handle exceptions raised within the command execution unless `#catch_exceptions?` is `false`.
  def run(input : ACON::Input::Interface = ACON::Input::ARGV.new, output : ACON::Output::Interface = ACON::Output::ConsoleOutput.new) : ACON::Command::Status | NoReturn
    ENV["LINES"] = @terminal.height.to_s
    ENV["COLUMNS"] = @terminal.width.to_s

    self.configure_io input, output

    begin
      exit_code = self.do_run input, output
    rescue ex : ::Exception
      raise ex unless @catch_exceptions

      self.render_exception ex, output

      exit_code = if ex.is_a?(ACON::Exception) && ex.code.positive?
                    ACON::Command::Status.new ex.code
                  else
                    ACON::Command::Status::FAILURE
                  end
    end

    if @auto_exit
      exit exit_code.value
    end

    exit_code
  end

  # Creates and `#add`s an `ACON::Command` with the provided *name*; executing the block when the command is invoked.
  def register(name : String, &block : ACON::Input::Interface, ACON::Output::Interface, ACON::Command -> ACON::Command::Status) : ACON::Command
    self.add(ACON::Commands::Generic.new(name, &block)).not_nil!
  end

  # Returns `true` if `self` only supports a single command.
  # See [Single Command Applications](/Console/Application/#Athena::Console::Application--single-command-applications) for more information.
  #
  # This is also the case if `#use_program_name_as_command?` is `true` and `PROGRAM_NAME`'s basename matches a registered command.
  def single_command? : Bool
    @single_command || !self.program_name_command.nil?
  end

  # Returns the `#name` and `#version` of the application.
  # Used when the `-V` or `--version` option is passed.
  def long_version : String
    "#{@name} <info>#{@version}</info>"
  end

  protected def command_name(input : ACON::Input::Interface) : String?
    return @default_command if @single_command

    self.program_name_command || input.first_argument
  end

  protected def program_name : String
    Path.new(PROGRAM_NAME).basename
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def configure_io(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
    if input.has_parameter? "--ansi", only_params: true
      output.decorated = true
    elsif input.has_parameter? "--no-ansi", only_params: true
      output.decorated = false
    end

    if input.has_parameter? "--no-interaction", "-n", only_params: true
      input.interactive = false
    end

    shell_verbosity = ENV["SHELL_VERBOSITY"]?.try(&.to_i?) || 0

    case shell_verbosity
    when -2 then output.verbosity = :silent
    when -1 then output.verbosity = :quiet
    when  1 then output.verbosity = :verbose
    when  2 then output.verbosity = :very_verbose
    when  3 then output.verbosity = :debug
    end

    if input.has_parameter? "--silent", only_params: true
      output.verbosity = :silent
      shell_verbosity = -2
    elsif input.has_parameter? "--quiet", "-q", only_params: true
      output.verbosity = :quiet
      shell_verbosity = -1
    else
      if input.has_parameter?("-vvv", "--verbose=3", only_params: true) || 3 == input.parameter("--verbose", false, true)
        output.verbosity = :debug
        shell_verbosity = 3
      elsif input.has_parameter?("-vv", "--verbose=2", only_params: true) || 2 == input.parameter("--verbose", false, true)
        output.verbosity = :very_verbose
        shell_verbosity = 2
      elsif input.has_parameter?("-v", "--verbose=1", only_params: true) || input.has_parameter?("--verbose") || input.parameter("--verbose", false, true)
        output.verbosity = :verbose
        shell_verbosity = 1
      end
    end

    if 0 > shell_verbosity
      input.interactive = false
    end

    ENV["SHELL_VERBOSITY"] = shell_verbosity.to_s
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def do_run(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if input.has_parameter? "--version", "-V", only_params: true
      output.puts self.long_version

      return ACON::Command::Status::SUCCESS
    end

    begin
      input.bind self.definition
    rescue ex : ::Exception
      # TODO: Make this part of the `rescue` after Crystal 1.13
      # Ignore errors as full binding/validation happens later when command is known
      raise ex unless ex.is_a? ACON::Exception
    end

    command_name = self.command_name input
    wants_help = false

    if input.has_parameter? "--help", "-h", only_params: true
      if command_name.nil?
        command_name = "help"
        input = ACON::Input::Hash.new(command_name: @default_command)
      else
        wants_help = true
      end
    end

    if command_name.nil?
      command_name = @default_command
      definition = self.definition
      definition.arguments.merge!({
        "command" => ACON::Input::Argument.new("command", :optional, definition.argument("command").description, command_name),
      })
    end

    begin
      @running_command = nil

      command = self.find command_name
    rescue ex : ::Exception
      if ex.is_a?(ACON::Exception::CommandNotFound) && !ex.is_a?(ACON::Exception::NamespaceNotFound) && input.is_a?(ACON::Input::ARGV) && !self.tree_descendants(command_name).empty?
        # The name is a namespace: an implicit node roots the walk, and lists its commands when invoked bare.
        command = ACON::Commands::Group.new command_name
        command.application = self
      elsif (ex.is_a?(ACON::Exception::CommandNotFound) && !ex.is_a?(ACON::Exception::NamespaceNotFound)) &&
            1 == (alternatives = ex.alternatives).size &&
            input.interactive?
        alternative = alternatives.not_nil!.first

        style = ACON::Style::Athena.new input, output
        output.puts ""
        output.puts ACON::Helper::Formatter.new.format_block "Command '#{command_name}' is not defined.", "error", true

        unless style.confirm "Do you want to run '#{alternative}' instead?", false
          # TODO: Handle dispatching

          return ACON::Command::Status::FAILURE
        end

        command = self.find alternative
      else
        # TODO: Handle dispatching

        begin
          if ex.is_a?(ACON::Exception::CommandNotFound) && (namespace = self.find_namespace command_name)
            ACON::Helper::Descriptor.new.describe(
              output.is_a?(ACON::Output::ConsoleOutputInterface) ? output.error_output : output,
              self,
              ACON::Descriptor::Context.new(
                format: "txt",
                raw_text: false,
                namespace: namespace,
                short: false
              )
            )

            return ACON::Command::Status::FAILURE
          end

          raise ex
        rescue ACON::Exception::NamespaceNotFound
          raise ex
        end
      end
    end

    if command.is_a? ACON::Commands::Lazy
      command = command.command
    end

    chain = nil
    if input.is_a?(ACON::Input::ARGV) && (resolved = self.resolve_command_tree command, input)
      command, input, chain = resolved
    end

    if wants_help
      help_command = self.get "help"

      if help_command.is_a? ACON::Commands::Lazy
        help_command = help_command.command
      end

      if help_command.is_a? ACON::Commands::Help
        help_command.command = command
      end

      command = help_command
    end

    previous_chain = @command_chain
    @running_command = command
    @command_chain = chain || ACON::CommandChain.new([{command, input}] of {ACON::Command, ACON::Input::Interface})

    begin
      exit_status = self.do_run_command command, input, output
    ensure
      # `@running_command` is left as is: `#render_exception` reports the synopsis of the command that failed.
      @command_chain = previous_chain
    end

    @running_command = nil

    exit_status
  end

  protected def do_run_command(command : ACON::Command, input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # TODO: Support input aware helpers.
    # TODO: Handle registering signable command listeners.

    command.run input, output

    # TODO: Handle eventing.
  end

  protected def default_input_definition : ACON::Input::Definition
    ACON::Input::Definition.new(
      ACON::Input::Argument.new("command", :required, "The command to execute"),
      ACON::Input::Option.new("help", "h", description: "Display help for the given command. When no command is given display help for the <info>#{@default_command}</info> command"),
      ACON::Input::Option.new("silent", description: "Do not output any message"),
      ACON::Input::Option.new("quiet", "q", description: "Only errors are displayed. All other output is suppressed"),
      ACON::Input::Option.new("verbose", "v|vv|vvv", description: "Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug"),
      ACON::Input::Option.new("version", "V", description: "Display this application version"),
      ACON::Input::Option.new("ansi", value_mode: :negatable, description: "Force (or disable --no-ansi) ANSI output", default: false),
      ACON::Input::Option.new("no-interaction", "n", description: "Do not ask any interactive question"),
    )
  end

  protected def default_commands : Array(ACON::Command)
    [
      Athena::Console::Commands::Help.new,
      Athena::Console::Commands::List.new,
      Athena::Console::Commands::DumpCompletion.new,
      Athena::Console::Commands::Complete.new,
    ]
  end

  protected def default_helper_set : ACON::Helper::HelperSet
    ACON::Helper::HelperSet.new(
      ACON::Helper::Formatter.new,
      ACON::Helper::Question.new
    )
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def do_render_exception(ex : ::Exception, output : ACON::Output::Interface) : Nil
    loop do
      message = (ex.message || "").strip

      if message.empty? || ACON::Output::Verbosity::VERBOSE <= output.verbosity
        title = "  [#{ex.class}]  "
        len = ACON::Helper.width title
      else
        len = 0
        title = ""
      end

      width = @terminal.width ? @terminal.width - 1 : Int32::MAX
      lines = [] of Tuple(String, Int32)

      message.split(/(?:\r?\n)/) do |line|
        self.split_string_by_width(line, width - 4) do |l|
          line_length = ACON::Helper.width(l) + 4
          lines << {l, line_length}

          len = Math.max line_length, len
        end
      end

      messages = [] of String

      if !ex.is_a?(ACON::Exception) || ACON::Output::Verbosity::VERBOSE <= output.verbosity
        if trace = ex.backtrace?.try &.first
          filename = nil
          line = nil

          if match = trace.match(/(\w+\.cr):(\d+)/)
            filename = if f = match[1]?
                         File.basename f
                       end
            line = match[2]?
          end

          messages << %(<comment>#{ACON::Formatter::Output.escape "In #{filename || "n/a"} line #{line || "n/a"}:"}</comment>)
        end
      end

      messages << (empty_line = "<error>#{" "*len}</error>")

      if messages.empty? || ACON::Output::Verbosity::VERBOSE <= output.verbosity
        messages << "<error>#{title}#{" "*(Math.max(0, len - ACON::Helper.width(title)))}</error>"
      end

      lines.each do |l|
        messages << "<error>  #{ACON::Formatter::Output.escape l[0]}  #{" "*(len - l[1])}</error>"
      end

      messages << empty_line
      messages << ""

      messages.each do |m|
        output.puts m, :quiet
      end

      if (ACON::Output::Verbosity::VERBOSE <= output.verbosity) && (t = ex.backtrace?)
        output.puts "<comment>Exception trace:</comment>", :quiet

        # TODO: Improve backtrace rendering.
        t.each do |l|
          output.puts " #{l}"
        end

        output.puts "", :quiet
      end

      break unless ex = ex.cause
    end
  end

  protected def extract_namespace(name : String, limit : Int32? = nil) : String
    # Pop off the shortcut name of the command.
    parts = name.split(':').tap &.pop

    (limit.nil? ? parts : parts[0...limit]).join ':'
  end

  protected def render_exception(ex : ::Exception, output : ACON::Output::ConsoleOutputInterface) : Nil
    self.render_exception ex, output.error_output
  end

  protected def render_exception(ex : ::Exception, output : ACON::Output::Interface) : Nil
    output.puts "", :quiet

    self.do_render_exception ex, output

    if running_command = @running_command
      output.puts "<info>#{ACON::Formatter::Output.escape running_command.synopsis}</info>", :quiet
      output.puts "", :quiet
    end
  end

  private def abbreviation_suggestions(abbreviations : Array(String)) : String
    %(    #{abbreviations.join("\n    ")})
  end

  # Re-emits the application options bound at a tree level as tokens, so that the leaf input carries them too.
  private def application_option_tokens(input : ACON::Input::Interface, consumed : Array(String)) : Array(String)
    tokens = [] of String
    values = input.options

    self.definition.options.each_value do |option|
      name = option.name
      value = values[name]?

      next if value == option.default

      if !option.accepts_value?
        # The token is replayed as it was given, so that a repeated shortcut such as `-vv` keeps its meaning.
        given = (option.shortcut || "").split('|', remove_empty: true).map { |shortcut| "-#{shortcut}" }
        tokens << (value ? (consumed.find { |token| "--#{name}" == token || given.includes?(token) } || "--#{name}") : "--no-#{name}")
      elsif value.nil?
        tokens << "--#{name}"
      else
        (value.is_a?(Array) ? value : [value]).each do |v|
          tokens << "--#{name}=#{v}"
        end
      end
    end

    tokens
  end

  private def extract_all_namespaces(name : String) : Array(String)
    # Pop off the shortcut name of the command.
    parts = name.split(':').tap &.pop

    namespaces = [] of String

    parts.each do |p|
      namespaces << if namespaces.empty?
        p
      else
        "#{namespaces.last}:#{p}"
      end
    end

    namespaces
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def find_alternatives(name : String, collection : Enumerable(String)) : Array(String)
    alternatives = Hash(String, Int32).new
    threshold = 1_000

    collection_parts = Hash(String, Array(String)).new
    collection.each do |item|
      collection_parts[item] = item.split ':'
    end

    name.split(':').each_with_index do |sub_name, idx|
      collection_parts.each do |collection_name, parts|
        exists = alternatives.has_key? collection_name

        if exists && parts[idx]?.nil?
          alternatives[collection_name] += threshold
          next
        elsif parts[idx]?.nil?
          next
        end

        lev = Levenshtein.distance sub_name, parts[idx]

        if lev <= sub_name.size / 3 || !sub_name.empty? && parts[idx].includes? sub_name
          alternatives[collection_name] = exists ? alternatives[collection_name] + lev : lev
        elsif exists
          alternatives[collection_name] += threshold
        end
      end
    end

    collection.each do |item|
      lev = Levenshtein.distance name, item
      if lev <= name.size / 3 || item.includes? name
        alternatives[item] = (current = alternatives[item]?) ? current - lev : lev
      end
    end

    alternatives.select! { |_, lev| lev < 2 * threshold }

    alternatives.keys.sort!
  end

  private def init : Nil
    return if @initialized

    @initialized = true

    self.default_commands.each do |command|
      self.add command
    end
  end

  # Returns the name of the registered command matching `PROGRAM_NAME`'s basename if `#use_program_name_as_command?` is `true`, otherwise `nil`.
  private def program_name_command : String?
    return unless @use_program_name_as_command

    program_name = self.program_name
    program_name if self.has? program_name
  end

  # Resolves a spaced sub-command invocation through the tree derived from registered command names.
  #
  # Returns the leaf command, the input it must run with, and the resolved chain,
  # or `nil` when the resolved command has no registered descendants and the regular, flat pipeline applies.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  private def resolve_command_tree(command : ACON::Command, input : ACON::Input::ARGV) : {ACON::Command, ACON::Input::ARGV, ACON::CommandChain}?
    path = command.name
    return if self.single_command? || self.tree_descendants(path).empty?

    tokens = input.raw_tokens
    node = self.has?(path) ? command : nil
    is_root = true
    application_options = [] of String
    levels = [] of {ACON::Command, ACON::Input::Interface}

    loop do
      definition = ACON::Input::Definition.new

      if node
        definition.options = node.native_definition.options.values
        definition << self.definition.options.values
      else
        definition.options = self.definition.options.values
      end

      if is_root
        definition.arguments = self.definition.arguments.values
      end

      definition.ignore_extra_arguments = true

      level_input = ACON::Input::ARGV.new tokens
      level_input.bind definition
      unparsed = level_input.unparsed_tokens
      consumed = tokens[0, tokens.size - unparsed.size]

      # No sub-command was given, or `--` marked the remaining tokens as this node's own arguments.
      break if unparsed.empty? || "--" == consumed.last? || "--" == unparsed.first

      segment = unparsed.shift
      child_path = "#{path}:#{segment}"

      # An alias of the current node is not a sub-command.
      has = self.has?(child_path) && self.get(child_path).name != path

      if !has && self.tree_descendants(child_path).empty?
        raise self.unknown_segment_exception(segment, path) if node.nil? || node.native_definition.arguments.empty?

        # The segment names no sub-command: it starts the node's own arguments.
        break
      end

      application_options.concat self.application_option_tokens(level_input, consumed)

      if node
        levels << {node.is_a?(ACON::Commands::Lazy) ? node.command : node, level_input}
      end

      if has
        node = self.get child_path
        canonical_name = node.name

        # An alias names the command it points to, unless that would orphan the sub-commands registered under it.
        if !self.tree_descendants(canonical_name).empty? || self.tree_descendants(child_path).empty?
          child_path = canonical_name
        end
      else
        node = nil
      end

      path = child_path
      tokens = unparsed
      is_root = false

      break if has && self.tree_descendants(child_path).empty?
    end

    return if is_root

    if self.has? path
      command = self.get path
      command = command.command if command.is_a? ACON::Commands::Lazy
    else
      # Implicit node: no command is registered at this level, it lists its sub-commands.
      command = ACON::Commands::Group.new path
      command.application = self
    end

    leaf_input = ACON::Input::ARGV.new [path].concat(application_options).concat(tokens)
    leaf_input.interactive = input.interactive?

    if stream = input.stream
      leaf_input.stream = stream
    end

    levels << {command, leaf_input}

    {command, leaf_input, ACON::CommandChain.new(levels)}
  end

  private def split_string_by_width(line : String, width : Int32, & : String -> Nil) : Nil
    if line.empty?
      return yield line
    end

    line.each_char.each_slice(width).map(&.join).each do |set|
      yield set
    end
  end

  # Returns the registered command names below the provided *path*, excluding aliases of the command registered at *path* itself.
  private def tree_descendants(path : String) : Array(String)
    names = @commands.keys
    if command_loader = @command_loader
      names.concat command_loader.names
    end

    prefix = "#{path}:"

    names.select do |name|
      name.starts_with?(prefix) && (!(command = @commands[name]?) || command.name != path)
    end
  end

  private def unknown_segment_exception(segment : String, path : String) : ACON::Exception::CommandNotFound
    message = "There is no command '#{segment}' under '#{path.tr(":", " ")}'."

    children = Hash(String, String).new
    self.tree_descendants(path).each do |name|
      child_segment = name[(path.size + 1)..].split(':').first
      children[child_segment] = "#{path}:#{child_segment}"
    end

    matching_segments = self.find_alternatives segment, children.keys
    alternatives = children.select { |child_segment, _| matching_segments.includes? child_segment }.values

    unless alternatives.empty?
      message += "\n\nDid you mean one of these?\n    #{alternatives.join("\n    ")}"
    end

    ACON::Exception::CommandNotFound.new message, alternatives
  end
end
