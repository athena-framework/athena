# An `ACON::Input::Interface` based on a [Hash](https://crystal-lang.org/api/Hash.html).
#
# Primarily useful for manually invoking commands, or as part of tests.
#
# ```
# ACON::Input::Hash.new(name: "George", "--foo": "bar")
# ```
#
# The keys of the input should be the name of the argument.
# Options should have `--` prefixed to their name.
class Athena::Console::Input::Hash < Athena::Console::Input
  @parameters : ::Hash(String, ACON::Input::Value)

  def self.new(*args : _) : self
    new args
  end

  def self.new(**args : _) : self
    new args.to_h
  end

  def initialize(args : ::Hash = ::Hash(NoReturn, NoReturn).new, definition : ACON::Input::Definition? = nil)
    hash = ::Hash(String, ACON::Input::Value).new

    args.each do |key, value|
      hash[key.to_s] = ACON::Input::Value.from_value value
    end

    @parameters = hash

    super definition
  end

  def initialize(args : Enumerable, definition : ACON::Input::Definition? = nil)
    hash = ::Hash(String, ACON::Input::Value).new

    args.each do |arg|
      hash[arg.to_s] = ACON::Input::Value::Nil.new
    end

    @parameters = hash

    super definition
  end

  # :inherit:
  def first_argument : String?
    @parameters.each do |name, value|
      next if name.starts_with? '-'

      return value.value.as(String)
    end

    nil
  end

  # :inherit:
  def has_parameter?(*values : String, only_params : Bool = false) : Bool
    @parameters.each do |name, value|
      value = value.value
      value = name unless value.is_a? Number
      return false if only_params && "--" == value
      return true if values.includes? value
    end

    false
  end

  # :inherit:
  def parameter(value : String, default : _ = false, only_params : Bool = false)
    @parameters.each do |name, v|
      return default if only_params && ("--" == name || "--" == value)
      return v.value if value == name
    end

    default
  end

  protected def parse : Nil
    @parameters.each do |name, value|
      return if "--" == name

      if name.starts_with? "--"
        self.add_long_option name.lchop("--"), value
      elsif name.starts_with? '-'
        self.add_short_option name.lchop('-'), value
      else
        self.add_argument name, value
      end
    end
  end

  private def add_argument(name : String, value : ACON::Input::Value) : Nil
    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' argument does not exist." if !@definition.has_argument? name

    @arguments[name] = value
  end

  private def add_long_option(name : String, value : ACON::Input::Value) : Nil
    unless @definition.has_option?(name)
      raise ACON::Exceptions::InvalidOption.new "The '--#{name}' option does not exist." unless @definition.has_negation? name

      option_name = @definition.negation_to_name name
      return @options[option_name] = ACON::Input::Value::Bool.new false
    end

    option = @definition.option name

    if value.is_a? ACON::Input::Value::Nil
      raise ACON::Exceptions::InvalidOption.new "The '--#{option.name}' option requires a value." if option.value_required?
      value = ACON::Input::Value::Bool.new(true) if !option.is_array? && !option.value_optional?
    end

    @options[name] = value
  end

  private def add_short_option(name : String, value : ACON::Input::Value) : Nil
    name = name.to_s

    raise ACON::Exceptions::InvalidOption.new "The '-#{name}' option does not exist." if !@definition.has_shortcut? name

    self.add_long_option @definition.option_for_shortcut(name).name, value
  end
end
