# Represents a value (or array of ) provided to a command as optional un-ordered flags
# that be setup to accept a value, or represent a boolean flag.
# Options can also have an optional shortcut, default value, and/or description.
#
# Options are specified with two dashes, or one dash when using the shortcut.
# For example, `./console test --yell --dir=src -v`.
# We have one option representing a boolean value, providing a value to another, and using the shortcut of another.
#
# Options can be added via the `ACON::Command#option` method,
# or by instantiating one manually as part of an `ACON::Input::Definition`.
# The value of the option could then be accessed via one of the `ACON::Input::Interface#option` overloads.
#
# See `ACON::Input::Interface` for more examples on how arguments/options are parsed, and how they can be accessed.
class Athena::Console::Input::Option
  @[Flags]
  # Represents the possible vale types of an `ACON::Input::Option`.
  #
  # Value modes can also be combined using the [Enum.[]](https://crystal-lang.org/api/Enum.html#%5B%5D%28%2Avalues%29-macro) macro.
  # For example, `ACON::Input::Option::Value[:required, :is_array]` which defines a required array option.
  enum Value
    # Represents a boolean flag option that will be `true` if provided, otherwise `false`.
    # E.g. `--yell`.
    NONE = 0

    # Represents an option that _MUST_ have a value if provided.
    # The option itself is still optional.
    # E.g. `--dir=src`.
    REQUIRED

    # Represents an option that _MAY_ have a value, but it is not a requirement.
    # E.g. `--yell` or `--yell=loud`.
    #
    # When using the option value mode, it can be hard to distinguish between passing an option without a value and not passing it at all.
    # In this case you should set the default of the option to `false`, instead of the default of `nil`.
    # Then you would be able to tell it wasn't passed by the value being `false`, passed without a value as `nil`, and passed with a value.
    #
    # NOTE: In this context you will need to work with the raw `String?` representation of the value due to the union of types the value could be.
    OPTIONAL

    # Represents an option that can be provided multiple times to produce an array of values.
    # E.g. `--dir=/foo --dir=/bar`.
    IS_ARRAY

    # Similar to `NONE`, but also accepts its negation.
    # E.g. `--yell` or `--no-yell`.
    NEGATABLE

    def accepts_value? : Bool
      self.required? || self.optional?
    end
  end

  # Returns the name of `self`.
  getter name : String

  # Returns the shortcut of `self`, if any.
  getter shortcut : String?

  # Returns the `ACON::Input::Option::Value` of `self`.
  getter value_mode : ACON::Input::Option::Value

  # Returns the description of `self`.
  getter description : String

  @default : ACON::Input::Value? = nil
  @suggested_values : Array(String) | Proc(ACON::Completion::Input, Array(String)) | Nil

  def initialize(
    name : String,
    shortcut : String | Enumerable(String) | Nil = nil,
    @value_mode : ACON::Input::Option::Value = :none,
    @description : String = "",
    default = nil,
    @suggested_values : Array(String) | Proc(ACON::Completion::Input, Array(String)) | Nil = nil
  )
    @name = name.lchop "--"

    raise ACON::Exceptions::InvalidArgument.new "An option name cannot be blank." if name.blank?

    unless shortcut.nil?
      if shortcut.is_a? Enumerable
        shortcut = shortcut.join '|'
      end

      shortcut = shortcut.lchop('-').split(/(?:\|)-?/, remove_empty: true).map(&.strip.lchop('-'))

      # Ensure each grouping contains only the same character
      shortcut.each do |s|
        unless s.split("").uniq!.size == 1
          raise ACON::Exceptions::InvalidArgument.new "An option shortcut must consist of the same character, got '#{s}'."
        end
      end

      shortcut = shortcut.join '|'

      raise ACON::Exceptions::InvalidArgument.new "An option shortcut cannot be blank." if shortcut.blank?
    end

    @shortcut = shortcut

    if @suggested_values && !self.accepts_value?
      raise ACON::Exceptions::InvalidArgument.new "Cannot set suggested values if the option does not accept a value."
    end

    if @value_mode.is_array? && !self.accepts_value?
      raise ACON::Exceptions::InvalidArgument.new " Cannot have VALUE::IS_ARRAY option mode when the option does not accept a value."
    end

    if @value_mode.negatable? && self.accepts_value?
      raise ACON::Exceptions::InvalidArgument.new " Cannot have VALUE::NEGATABLE option mode if the option also accepts a value."
    end

    self.default = default
  end

  def_equals @name, @shortcut, @default, @value_mode

  # Returns the default value of `self`, if any.
  def default
    @default.try do |value|
      case value
      when ACON::Input::Value::Array
        value.value.map &.value
      else
        value.value
      end
    end
  end

  # Returns the default value of `self`, if any, converted to the provided *type*.
  def default(type : T.class) : T forall T
    {% if T.nilable? %}
      self.default.as T
    {% else %}
      @default.not_nil!.get T
    {% end %}
  end

  # Sets the default value of `self`.
  def default=(default = nil) : Nil
    raise ACON::Exceptions::Logic.new "Cannot set a default value when using Value::NONE mode." if @value_mode.none? && !default.nil?

    if @value_mode.is_array?
      if default.nil?
        return @default = ACON::Input::Value::Array.new
      else
        raise ACON::Exceptions::Logic.new "Default value for an array option must be an array." unless default.is_a? Array
      end
    end

    @default = ACON::Input::Value.from_value (@value_mode.accepts_value? || @value_mode.negatable?) ? default : false
  end

  # Returns `true` if this option is able to suggest values, otherwise `false`
  def has_completion? : Bool
    !@suggested_values.nil?
  end

  # Determines what values should be added to the possible *suggestions* based on the provided *input*.
  def complete(input : ACON::Completion::Input, suggestions : ACON::Completion::Suggestions) : Nil
    return unless values = @suggested_values

    if values.is_a?(Proc)
      values = values.call input
    end

    suggestions.suggest_values values
  end

  # Returns `true` if `self` is able to accept a value, otherwise `false`.
  def accepts_value? : Bool
    @value_mode.accepts_value?
  end

  # Returns `true` if `self` is a required argument, otherwise `false`.
  # ameba:disable Style/PredicateName
  def is_array? : Bool
    @value_mode.is_array?
  end

  # Returns `true` if `self` is negatable, otherwise `false`.
  def negatable? : Bool
    @value_mode.negatable?
  end

  # Returns `true` if `self` accepts a value and it is required, otherwise `false`.
  def value_required? : Bool
    @value_mode.required?
  end

  # Returns `true` if `self` accepts a value but is optional, otherwise `false`.
  def value_optional? : Bool
    @value_mode.optional?
  end
end
