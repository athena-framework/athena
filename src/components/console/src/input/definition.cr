# Represents a collection of `ACON::Input::Argument`s and `ACON::Input::Option`s that are to be parsed from an `ACON::Input::Interface`.
#
# Can be used to set the inputs of an `ACON::Command` via the `ACON::Command#definition=` method if so desired,
# instead of using the dedicated methods.
class Athena::Console::Input::Definition
  getter options : ::Hash(String, ACON::Input::Option) = ::Hash(String, ACON::Input::Option).new
  getter arguments : ::Hash(String, ACON::Input::Argument) = ::Hash(String, ACON::Input::Argument).new

  @last_array_argument : ACON::Input::Argument? = nil
  @last_optional_argument : ACON::Input::Argument? = nil

  @shortcuts = ::Hash(String, String).new
  @negations = ::Hash(String, String).new

  getter required_argument_count : Int32 = 0

  def self.new(definition : ::Hash(String, ACON::Input::Option) | ::Hash(String, ACON::Input::Argument)) : self
    new definition.values
  end

  def self.new(*definitions : ACON::Input::Argument | ACON::Input::Option) : self
    new definitions.to_a
  end

  def initialize(definition : Array(ACON::Input::Argument | ACON::Input::Option) = Array(ACON::Input::Argument | ACON::Input::Option).new)
    self.definition = definition
  end

  # Adds the provided *argument* to `self`.
  def <<(argument : ACON::Input::Argument) : Nil
    raise ACON::Exception::Logic.new "An argument with the name '#{argument.name}' already exists." if @arguments.has_key?(argument.name)

    if last_array_argument = @last_array_argument
      raise ACON::Exception::Logic.new "Cannot add a required argument '#{argument.name}' after Array argument '#{last_array_argument.name}'."
    end

    if argument.required? && (last_optional_argument = @last_optional_argument)
      raise ACON::Exception::Logic.new "Cannot add required argument '#{argument.name}' after the optional argument '#{last_optional_argument.name}'."
    end

    if argument.is_array?
      @last_array_argument = argument
    end

    if argument.required?
      @required_argument_count += 1
    else
      @last_optional_argument = argument
    end

    @arguments[argument.name] = argument
  end

  # Adds the provided *options* to `self`.
  def <<(option : ACON::Input::Option) : Nil
    if self.has_option?(option.name) && option != self.option(option.name)
      raise ACON::Exception::Logic.new "An option named '#{option.name}' already exists."
    end

    if self.has_negation?(option.name)
      raise ACON::Exception::Logic.new "An option named '#{option.name}' already exists."
    end

    if shortcut = option.shortcut
      shortcut.split('|', remove_empty: true) do |s|
        if self.has_shortcut?(s) && option != self.option_for_shortcut(s)
          raise ACON::Exception::Logic.new "An option with shortcut '#{s}' already exists."
        end
      end
    end

    @options[option.name] = option

    if shortcut
      shortcut.split('|', remove_empty: true) do |s|
        @shortcuts[s] = option.name
      end
    end

    if option.negatable?
      negated_name = "no-#{option.name}"

      raise ACON::Exception::Logic.new "An option named '#{negated_name}' already exists." if self.has_option? negated_name

      @negations[negated_name] = option.name
    end
  end

  # Adds the provided *arguments* to `self`.
  def <<(arguments : Array(ACON::Input::Argument | ACON::Input::Option)) : Nil
    arguments.each do |arg|
      self.<< arg
    end
  end

  # Overrides the arguments and options of `self` to those in the provided *definition*.
  def definition=(definition : Array(ACON::Input::Argument | ACON::Input::Option)) : Nil
    arguments = Array(ACON::Input::Argument).new
    options = Array(ACON::Input::Option).new

    definition.each do |d|
      case d
      in ACON::Input::Argument then arguments << d
      in ACON::Input::Option   then options << d
      end
    end

    self.arguments = arguments
    self.options = options
  end

  # Overrides the arguments of `self` to those in the provided *arguments* array.
  def arguments=(arguments : Array(ACON::Input::Argument)) : Nil
    @arguments.clear
    @required_argument_count = 0
    @last_array_argument = nil
    @last_optional_argument = nil

    self.<< arguments
  end

  # Returns the `ACON::Input::Argument` with the provided *name_or_index*,
  # otherwise raises `ACON::Exception::InvalidArgument` if that argument is not defined.
  def argument(name_or_index : String | Int32) : ACON::Input::Argument
    raise ACON::Exception::InvalidArgument.new "The argument '#{name_or_index}' does not exist." unless self.has_argument? name_or_index

    case name_or_index
    in String then @arguments[name_or_index]
    in Int32  then @arguments.values[name_or_index]
    end
  end

  # Returns `true` if `self` has an argument with the provided *name_or_index*.
  def has_argument?(name_or_index : String | Int32) : Bool
    case name_or_index
    in String then @arguments.has_key? name_or_index
    in Int32  then !@arguments.values.[name_or_index]?.nil?
    end
  end

  # Returns the number of `ACON::Input::Argument`s defined within `self`.
  def argument_count : Int32
    !@last_array_argument.nil? ? Int32::MAX : @arguments.size
  end

  # Returns a `::Hash` whose keys/values represent the names and default values of the `ACON::Input::Argument`s defined within `self`.
  def argument_defaults : ::Hash
    @arguments.to_h do |(name, arg)|
      {name, arg.default}
    end
  end

  # Overrides the options of `self` to those in the provided *options* array.
  def options=(options : Array(ACON::Input::Option)) : Nil
    @options.clear
    @shortcuts.clear
    @negations.clear

    self.<< options
  end

  # Returns the `ACON::Input::Option` with the provided *name_or_index*,
  # otherwise raises `ACON::Exception::InvalidArgument` if that option is not defined.
  def option(name_or_index : String | Int32) : ACON::Input::Option
    raise ACON::Exception::InvalidArgument.new "The '--#{name_or_index}' option does not exist." unless self.has_option? name_or_index

    case name_or_index
    in String then @options[name_or_index]
    in Int32  then @options.values[name_or_index]
    end
  end

  # Returns a `::Hash` whose keys/values represent the names and default values of the `ACON::Input::Option`s defined within `self`.
  def option_defaults : ::Hash
    @options.to_h do |(name, opt)|
      {name, opt.default}
    end
  end

  # Returns `true` if `self` has an option with the provided *name_or_index*.
  def has_option?(name_or_index : String | Int32) : Bool
    case name_or_index
    in String then @options.has_key? name_or_index
    in Int32  then !@options.values.[name_or_index]?.nil?
    end
  end

  # Returns `true` if `self` has a shortcut with the provided *name*, otherwise `false`.
  def has_shortcut?(name : String | Char) : Bool
    @shortcuts.has_key? name.to_s
  end

  # Returns `true` if `self` has a negation with the provided *name*, otherwise `false`.
  def has_negation?(name : String | Char) : Bool
    @negations.has_key? name.to_s
  end

  # Returns the name of the `ACON::Input::Option` that maps to the provided *negation*.
  def negation_to_name(negation : String) : String
    raise ACON::Exception::InvalidArgument.new "The '--#{negation}' option does not exist." unless self.has_negation? negation

    @negations[negation]
  end

  # Returns the name of the `ACON::Input::Option` with the provided *shortcut*.
  def option_for_shortcut(shortcut : String | Char) : ACON::Input::Option
    self.option self.shortcut_to_name shortcut.to_s
  end

  # Returns an optionally *short* synopsis based on the `ACON::Input::Argument`s and `ACON::Input::Option`s defined within `self`.
  #
  # The synopsis being the [docopt](http://docopt.org) string representing the expected options/arguments.
  # E.g. `<name> move <x> <y> [--speed=<kn>]`.
  # ameba:disable Metrics/CyclomaticComplexity
  def synopsis(short : Bool = false) : String
    elements = [] of String

    if short && !@options.empty?
      elements << "[options]"
    elsif !short
      @options.each_value do |opt|
        value = ""

        if opt.accepts_value?
          value = sprintf(
            " %s%s%s",
            opt.value_optional? ? "[" : "",
            opt.name.upcase,
            opt.value_optional? ? "]" : "",
          )
        end

        shortcut = (s = opt.shortcut) ? sprintf("-%s|", s) : ""
        negation = opt.negatable? ? sprintf("|--no-%s", opt.name) : ""

        elements << "[#{shortcut}--#{opt.name}#{value}#{negation}]"
      end
    end

    if !elements.empty? && !@arguments.empty?
      elements << "[--]"
    end

    tail = ""

    @arguments.each_value do |arg|
      element = "<#{arg.name}>"
      element += "..." if arg.is_array?

      unless arg.required?
        element = "[#{element}"
        tail += "]"
      end

      elements << element
    end

    %(#{elements.join " "}#{tail})
  end

  protected def shortcut_to_name(shortcut : String) : String
    raise ACON::Exception::InvalidArgument.new "The '-#{shortcut}' option does not exist." unless self.has_shortcut? shortcut

    @shortcuts[shortcut]
  end
end
