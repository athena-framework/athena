require "./interface"
require "./streamable"

require "./value/*"

# Common base implementation of `ACON::Input::Interface`.
abstract class Athena::Console::Input
  include Athena::Console::Input::Streamable

  # :inherit:
  property stream : IO? = nil

  # :inherit:
  property? interactive : Bool = true

  @arguments = ::Hash(String, ACON::Input::Value).new
  @definition : ACON::Input::Definition
  @options = ::Hash(String, ACON::Input::Value).new

  def initialize(definition : ACON::Input::Definition? = nil)
    if definition.nil?
      @definition = ACON::Input::Definition.new
    else
      @definition = definition
      self.bind definition
      self.validate
    end
  end

  # :inherit:
  def argument(name : String) : String?
    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' argument does not exist." unless @definition.has_argument? name

    value = if @arguments.has_key? name
              @arguments[name]
            else
              @definition.argument(name).default
            end

    case value
    when Nil, ACON::Input::Value::Nil then nil
    else
      value.to_s
    end
  end

  # :inherit:
  def argument(name : String, type : T.class) : T forall T
    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' argument does not exist." unless @definition.has_argument? name

    {% unless T.nilable? %}
      if !@definition.argument(name).required? && @definition.argument(name).default.nil?
        raise ACON::Exceptions::Logic.new "Cannot cast optional argument '#{name}' to non-nilable type '#{T}' without a default."
      end
    {% end %}

    if @arguments.has_key? name
      return @arguments[name].get T
    end

    @definition.argument(name).default T
  end

  # :inherit:
  def set_argument(name : String, value : _) : Nil
    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' argument does not exist." unless @definition.has_argument? name

    @arguments[name] = ACON::Input::Value.from_value value
  end

  # :inherit:
  def arguments : ::Hash
    @definition.argument_defaults.merge(self.resolve @arguments)
  end

  # :inherit:
  def has_argument?(name : String) : Bool
    @definition.has_argument? name
  end

  # :inherit:
  def option(name : String) : String?
    if @definition.has_negation?(name)
      self.option(@definition.negation_to_name(name), Bool?).try do |v|
        return (!v).to_s
      end

      return
    end

    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' option does not exist." unless @definition.has_option? name

    value = if @options.has_key? name
              @options[name]
            else
              @definition.option(name).default
            end

    case value
    when Nil, ACON::Input::Value::Nil then nil
    else
      value.to_s
    end
  end

  # :inherit:
  def option(name : String, type : T.class) : T forall T
    {% if T <= Bool? %}
      if @definition.has_negation?(name)
        negated_name = @definition.negation_to_name(name)

        if @options.has_key? negated_name
          return !@options[negated_name].get T
        end

        raise "BUG: Didn't return negated value."
      end
    {% end %}

    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' option does not exist." unless @definition.has_option? name

    {% unless T <= Bool? %}
      raise ACON::Exceptions::Logic.new "Cannot cast negatable option '#{name}' to non 'Bool?' type." if @definition.option(name).negatable?
    {% end %}

    {% unless T.nilable? %}
      if !@definition.option(name).value_required? && !@definition.option(name).negatable? && @definition.option(name).default.nil?
        raise ACON::Exceptions::Logic.new "Cannot cast optional option '#{name}' to non-nilable type '#{T}' without a default."
      end
    {% end %}

    if @options.has_key? name
      return @options[name].get T
    end

    @definition.option(name).default T
  end

  # :inherit:
  def set_option(name : String, value : _) : Nil
    if @definition.has_negation?(name)
      return @options[@definition.negation_to_name(name)] = ACON::Input::Value.from_value !value
    end

    raise ACON::Exceptions::InvalidArgument.new "The '#{name}' option does not exist." unless @definition.has_option? name

    @options[name] = ACON::Input::Value.from_value value
  end

  # :inherit:
  def options : ::Hash
    @definition.option_defaults.merge(self.resolve @options)
  end

  # :inherit:
  def has_option?(name : String) : Bool
    @definition.has_option?(name) || @definition.has_negation?(name)
  end

  # :inherit:
  def bind(definition : ACON::Input::Definition) : Nil
    @arguments.clear
    @options.clear
    @definition = definition

    self.parse
  end

  protected abstract def parse : Nil

  # :inherit:
  def validate : Nil
    missing_args = @definition.arguments.keys.select do |arg|
      !@arguments.has_key?(arg) && @definition.argument(arg).required?
    end

    raise ACON::Exceptions::ValidationFailed.new %(Not enough arguments (missing: '#{missing_args.join(", ")}').) unless missing_args.empty?
  end

  private def resolve(hash : ::Hash(String, ACON::Input::Value)) : ::Hash
    hash.transform_values do |value|
      case value
      when ACON::Input::Value::Array
        value.value.map &.value
      else
        value.value
      end
    end
  end
end
