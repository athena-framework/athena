# An `ACON::Command` represents a concrete command that can be invoked via the CLI.
# All commands should inherit from this base type, but additional abstract subclasses can be used
# to share common logic for related command classes.
#
# ## Creating a Command
#
# A command is defined by extending `ACON::Command` and implementing the `#execute` method.
# For example:
#
# ```
# @[ACONA::AsCommand("app:create-user")]
# class CreateUserCommand < ACON::Command
#   protected def configure : Nil
#     # ...
#   end
#
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     # Implement all the business logic here.
#
#     # Indicates the command executed successfully.
#     ACON::Command::Status::SUCCESS
#   end
# end
# ```
#
# ### Command Lifecycle
#
# Commands have three lifecycle methods that are invoked when running the command:
#
# 1. `setup` (optional) - Executed before `#interact` and `#execute`. Can be used to setup state based on input data.
# 1. `interact` (optional) - Executed after `#setup` but before `#execute`. Can be used to check if any arguments/options are missing
# and interactively ask the user for those values. After this method, missing arguments/options will result in an error.
# 1. `execute` (required) - Contains the business logic for the command, returning the status of the invocation via `ACON::Command::Status`.
#
# ```
# @[ACONA::AsCommand("app:create-user")]
# class CreateUserCommand < ACON::Command
#   protected def configure : Nil
#     # ...
#   end
#
#   protected def setup(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
#     # ...
#   end
#
#   protected def interact(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
#     # ...
#   end
#
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     # Indicates the command executed successfully.
#     ACON::Command::Status::SUCCESS
#   end
# end
# ```
#
# ## Configuring the Command
#
# In most cases, a command is going to need to be configured to better fit its purpose.
# The `#configure` method can be used configure various aspects of the command,
# such as its name, description, `ACON::Input`s, help message, aliases, etc.
#
# ```
# protected def configure : Nil
#   self
#     .help("Creates a user...") # Shown when running the command with the `--help` option
#     .aliases("new-user")       # Alternate names for the command
#     .hidden                    # Hide the command from the list
#   # ...
# end
# ```
#
# TIP: The suggested way of setting the name and description of the command is via the `ACONA::AsCommand` annotation.
# This enables lazy command instantiation when used within the Athena framework. Checkout the [external documentation](/architecture/console/) for more information.
#
# The `#configure` command is called automatically at the end of the constructor method.
# If your command defines its own, be sure to call `super()` to also run the parent constructor.
# `super` may also be called _after_ setting the properties if they should be used to determine how to configure the command.
#
# ```
# class CreateUserCommand < ACON::Command
#   def initialize(@require_password : Bool = false)
#     super()
#   end
#
#   protected def configure : Nil
#     self
#       .argument("password", @require_password ? ACON::Input::Argument::Mode::REQUIRED : ACON::Input::Argument::Mode::OPTIONAL)
#   end
# end
# ```
#
# ### Output
#
# The `#execute` method has access to an `ACON::Output::Interface` instance that can be used to write messages to display.
# The `output` parameter should be used instead of `#puts` or `#print` to decouple the command from `STDOUT`.
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   # outputs multiple lines to the console (adding "\n" at the end of each line)
#   output.puts([
#     "User Creator",
#     "============",
#     "",
#   ])
#
#   # outputs a message followed by a "\n"
#   output.puts "Whoa!"
#
#   # outputs a message without adding a "\n" at the end of the line
#   output.print "You are about to "
#   output.print "create a user."
#
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# See `ACON::Output::Interface` for more information.
#
# ### Input
#
# In most cases, a command is going to have some sort of input arguments/options.
# These inputs can be setup in the `#configure` method, and accessed via the *input* parameter within `#execute`.
#
# ```
# protected def configure : Nil
#   self
#     .argument("username", :required, "The username of the user")
# end
#
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   # Retrieve the username as a String?
#   output.puts %(Hello #{input.argument "username"}!)
#
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# See `ACON::Input::Interface` for more information.
#
# ## Testing the Command
#
# `Athena::Console` also includes a way to test your console commands without needing to build and run a binary.
# A single command can be tested via an `ACON::Spec::CommandTester` and a whole application can be tested via an `ACON::Spec::ApplicationTester`.
#
# See `ACON::Spec` for more information.
abstract class Athena::Console::Command
  # Represents the execution status of an `ACON::Command`.
  #
  # The value of each member is used as the exit code of the invocation.
  enum Status
    # Represents a successful invocation with no errors.
    SUCCESS = 0

    # Represents that some error happened during invocation.
    FAILURE = 1

    # Represents the command was not used correctly, such as invalid options or missing arguments.
    INVALID = 2
  end

  private enum Synopsis
    SHORT
    LONG
  end

  # Returns the default name of `self`, or `nil` if it was not set.
  def self.default_name : String?
    {% begin %}
      {% if ann = @type.annotation ACONA::AsCommand %}
        {%
          name = (ann[0] || ann[:name])

          unless name
            ann.raise "Console command '#{@type}' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field."
          end
        %}

        {% if !ann[:hidden] && !ann[:aliases] %}
          {{name}}
        {% else %}
          {%
            name = name.split '|'
            name = name + (ann[:aliases] || [] of Nil)

            if ann[:hidden] && "" != name[0]
              name.unshift ""
            end
          %}
            {{name.join '|'}}
        {% end %}
      {% end %}
    {% end %}
  end

  # Returns the default description of `self`, or `nil` if it was not set.
  def self.default_description : String?
    {% if ann = @type.annotation ACONA::AsCommand %}
      {{ann[:description]}}
    {% end %}
  end

  # Returns the name of `self`.
  getter! name : String

  # Returns the `description of `self`.
  getter description : String = ""

  # Returns/sets the help template for `self`.
  #
  # See `#processed_help`.
  property help : String = ""

  # Returns the `ACON::Application` associated with `self`, otherwise `nil`.
  getter! application : ACON::Application

  # Returns/sets the list of aliases that may also be used to execute `self` in addition to its `#name`.
  property aliases : Array(String) = [] of String

  # Returns/sets an `ACON::Helper::HelperSet` on `self`.
  property helper_set : ACON::Helper::HelperSet? = nil

  # Returns `true` if `self` is hidden from the command list, otherwise `false`.
  getter? hidden : Bool = false

  # Returns if `self` is enabled in the current environment.
  #
  # Can be overridden to return `false` if it cannot run under the current conditions.
  getter? enabled : Bool = true

  # Returns the list of usages for `self`.
  #
  # See `#usage`.
  getter usages : Array(String) = [] of String

  @definition : ACON::Input::Definition = ACON::Input::Definition.new
  @full_definition : ACON::Input::Definition? = nil
  @ignore_validation_errors : Bool = false
  @synopsis = Hash(Synopsis, String).new
  @process_title : String? = nil

  def initialize(name : String? = nil)
    if name.nil? && (n = self.class.default_name)
      aliases = n.split '|'

      if (name = aliases.shift).empty?
        self.hidden true
        name = aliases.shift?
      end

      self.aliases aliases
    end

    unless name.nil?
      self.name name
    end

    if (@description.empty?) && (description = self.class.default_description)
      self.description description
    end

    self.configure
  end

  # Sets the aliases of `self`.
  def aliases(*aliases : String) : self
    self.aliases aliases.to_a
  end

  # :ditto:
  def aliases(aliases : Enumerable(String)) : self
    aliases.each &->validate_name(String)

    @aliases = aliases

    self
  end

  def application=(@application : ACON::Application?) : Nil
    if application = @application
      @helper_set = application.helper_set
    else
      @helper_set = nil
    end

    @full_definition = nil
  end

  # Adds an `ACON::Input::Argument` to `self` with the provided *name*.
  # Optionally supports setting its *mode*, *description*, and *default* value.
  def argument(name : String, mode : ACON::Input::Argument::Mode = :optional, description : String = "", default = nil) : self
    @definition << ACON::Input::Argument.new name, mode, description, default

    if full_definition = @full_definition
      full_definition << ACON::Input::Argument.new name, mode, description, default
    end

    self
  end

  def definition : ACON::Input::Definition
    @full_definition || self.native_definition
  end

  # Sets the `ACON::Input::Definition` on self.
  def definition(@definition : ACON::Input::Definition) : self
    @full_definition = nil

    self
  end

  # :ditto:
  def definition(*definitions : ACON::Input::Argument | ACON::Input::Option) : self
    self.definition definitions.to_a
  end

  # :ditto:
  def definition(definition : Array(ACON::Input::Argument | ACON::Input::Option)) : self
    @definition.definition = definition

    @full_definition = nil

    self
  end

  # Sets the `#description` of `self`.
  def description(@description : String) : self
    self
  end

  def name(name : String) : self
    self.validate_name name

    @name = name

    self
  end

  # Sets the `#help` of `self`.
  def help(@help : String) : self
    self
  end

  # Returns an `ACON:Helper::Interface` of the provided *helper_class*.
  #
  # ```
  # formatter = self.helper ACON::Helper::Formatter
  # # ...
  # ```
  def helper(helper_class : T.class) : T forall T
    unless helper_set = @helper_set
      raise ACON::Exceptions::Logic.new "Cannot retrieve helper '#{helper_class}' because there is no `ACON::Helper::HelperSet` defined. Did you forget to add your command to the application or to set the application on the command using '#application='? You can also set the HelperSet directly using '#helper_set='."
    end

    helper_set[helper_class].as T
  end

  # Hides `self` from the command list.
  def hidden(@hidden : Bool = true) : self
    self
  end

  # Adds an `ACON::Input::Option` to `self` with the provided *name*.
  # Optionally supports setting its *shortcut*, *value_mode*, *description*, and *default* value.
  def option(name : String, shortcut : String? = nil, value_mode : ACON::Input::Option::Value = :none, description : String = "", default = nil) : self
    @definition << ACON::Input::Option.new name, shortcut, value_mode, description, default

    if full_definition = @full_definition
      full_definition << ACON::Input::Option.new name, shortcut, value_mode, description, default
    end

    self
  end

  # Sets the process title of `self`.
  #
  # TODO: Implement this.
  def process_title(title : String) : self
    @process_title = title

    self
  end

  # The `#help` message can include some template variables for the command:
  #
  # * `%command.name%` - Returns the `#name` of `self`. E.g. `app:create-user`
  #
  # This method returns the `#help` message with these variables replaced.
  def processed_help : String
    is_single_command = (application = @application) && application.single_command?
    prog_name = Path.new(PROGRAM_NAME).basename
    full_name = is_single_command ? prog_name : "./#{prog_name} #{@name}"

    processed_help = self.help.presence || self.description

    { {"%command.name%", @name}, {"%command.full_name%", full_name} }.each do |(placeholder, replacement)|
      processed_help = processed_help.gsub placeholder, replacement
    end

    processed_help
  end

  # Returns a short synopsis of `self`, including its `#name` and expected arguments/options.
  # For example `app:user-create [--dry-run] [--] <username>`.
  def synopsis(short : Bool = false) : String
    key = short ? Synopsis::SHORT : Synopsis::LONG

    unless @synopsis.has_key? key
      @synopsis[key] = "#{@name} #{@definition.synopsis short}".strip
    end

    @synopsis[key]
  end

  # Adds a usage string that will displayed within the `Usage` section after the auto generated entry.
  def usage(usage : String) : self
    unless (name = @name) && usage.starts_with? name
      usage = "#{name} #{usage}"
    end

    @usages << usage

    self
  end

  # Makes the command ignore any input validation errors.
  def ignore_validation_errors : Nil
    @ignore_validation_errors = true
  end

  # Runs the command with the provided *input* and *output*, returning the status of the invocation as an `ACON::Command::Status`.
  def run(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    self.merge_application_definition

    begin
      input.bind self.definition
    rescue ex : ACON::Exceptions::ConsoleException
      raise ex unless @ignore_validation_errors
    end

    self.setup input, output

    # TODO: Allow setting process title

    if input.interactive?
      self.interact input, output
    end

    if input.has_argument?("command") && input.argument("command").nil?
      input.set_argument "command", self.name
    end

    input.validate

    self.execute input, output
  end

  protected def merge_application_definition(merge_args : Bool = true) : Nil
    return unless application = @application

    # TODO: Figure out if there is a better way to structure/store
    # the data to remove the .values call.
    full_definition = ACON::Input::Definition.new
    full_definition.options = @definition.options.values
    full_definition << application.definition.options.values

    if merge_args
      full_definition.arguments = application.definition.arguments.values
      full_definition << @definition.arguments.values
    else
      full_definition.arguments = @definition.arguments.values
    end

    @full_definition = full_definition
  end

  protected def native_definition
    @definition
  end

  # Executes the command with the provided *input* and *output*, returning the status of the invocation via `ACON::Command::Status`.
  #
  # This method _MUST_ be defined and implement the business logic for the command.
  protected abstract def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status

  # Can be overridden to configure the current command, such as setting the name, adding arguments/options, setting help information etc.
  protected def configure : Nil
  end

  # The related `ACON::Input::Definition` is validated _after_ this method is executed.
  # This method can be used to interactively ask the user for missing required arguments.
  protected def interact(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
  end

  # Called after the input has been bound, but before it has been validated.
  # Can be used to setup state of the command based on the provided input data.
  protected def setup(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
  end

  private def validate_name(name : String) : Nil
    raise ACON::Exceptions::InvalidArgument.new "Command name '#{name}' is invalid." if name.blank? || !name.matches? /^[^:]++(:[^:]++)*$/
  end
end
