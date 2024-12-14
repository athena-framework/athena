# Validates that a value is one of a given set of valid choices;
# can also be used to validate that each item in a collection is one of those valid values.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@role : String); end
#
#   @[Assert::Choice(["member", "moderator", "admin"])]
#   property role : String
# end
# ```
#
# # Configuration
#
# ## Required Arguments
#
# ### choices
#
# **Type:** `Array(String | Number::Primitive | Symbol)`
#
# The choices that are considered valid.
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This value is not a valid choice.`
#
# The message that will be shown if the value is not a valid choice and [multiple](#multiple) is `false`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ choices }}` - The available choices.
#
# ### multiple_message
#
# **Type:** `String` **Default:** `One or more of the given values is invalid.`
#
# The message that will be shown if one of the values is not a valid choice and [multiple](#multiple) is `true`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ choices }}` - The available choices.
#
# ### min_message
#
# **Type:** `String` **Default:** `You must select at least {{ limit }} choice.|You must select at least {{ limit }} choices.`
#
# The message that will be shown if too few choices are chosen as per the [range](#range) option.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ choices }}` - The available choices.
# * `{{ limit }}` - If [multiple](#multiple) is true, enforces that at most this many values may be selected in order to be valid.
#
# ### max_message
#
# **Type:** `String` **Default:** `You must select at most {{ limit }} choice.|You must select at most {{ limit }} choices.`
#
# The message that will be shown if too many choices are chosen as per the [range](#range) option.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ choices }}` - The available choices.
# * `{{ limit }}` - If [multiple](#multiple) is true, enforces that no more than this many values may be selected in order to be valid.
#
# ### range
#
# **Type:** `::Range?` **Default:** `nil`
#
# If [multiple](#multiple) is true, is used to define the "range" of how many choices must be valid for the value to be considered valid.
# For example, if set to `(3..)`, but there are only 2 valid items in the input enumerable then validation will fail.
#
# Beginless/endless ranges can be used to define only a lower/upper bound.
#
# ### multiple
#
# **Type:** `Bool` **Default:** `false`
#
# If `true`, the input value is expected to be an `Enumerable` instead of a single scalar value.
# The constraint will check each item in the enumerable is valid choice.
#
# ### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# ### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
class Athena::Validator::Constraints::Choice < Athena::Validator::Constraint
  NO_SUCH_CHOICE_ERROR = "c7398ea5-e787-4ee9-9fca-5f2c130614d6"
  TOO_FEW_ERROR        = "3573357d-c9a8-4633-a742-c001086fd5aa"
  TOO_MANY_ERROR       = "91d0d22b-a693-4b9c-8b41-bc6392cf89f4"

  @@error_names = {
    NO_SUCH_CHOICE_ERROR => "NO_SUCH_CHOICE_ERROR",
    TOO_FEW_ERROR        => "TOO_FEW_ERROR",
    TOO_MANY_ERROR       => "TOO_MANY_ERROR",
  }

  getter choices : Array(String | Number::Primitive | Symbol)

  getter multiple_message : String
  getter min_message : String
  getter max_message : String

  getter min : Number::Primitive?
  getter max : Number::Primitive?

  getter? multiple : Bool

  def self.new(
    choices : Array(String | Number::Primitive | Symbol),
    message : String = "This value is not a valid choice.",
    multiple_message : String = "One or more of the given values is invalid.",
    min_message : String = "You must select at least {{ limit }} choice.|You must select at least {{ limit }} choices.",
    max_message : String = "You must select at most {{ limit }} choice.|You must select at most {{ limit }} choices.",
    multiple : Bool = false,
    range : ::Range? = nil,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    new choices.map(&.as(String | Number::Primitive | Symbol)), message, multiple_message, min_message, max_message, multiple, range.try(&.begin), range.try(&.end), groups, payload
  end

  private def initialize(
    @choices : Array(String | Number::Primitive | Symbol),
    message : String,
    @multiple_message : String,
    @min_message : String,
    @max_message : String,
    @multiple : Bool,
    @min : Number::Primitive?,
    @max : Number::Primitive?,
    groups : Array(String) | String | Nil,
    payload : Hash(String, String)?,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : Enumerable?, constraint : AVD::Constraints::Choice) : Nil
      return if value.nil?

      self.raise_invalid_type(value, "Enumerable") unless constraint.multiple?

      choices = constraint.choices

      value.each do |v|
        unless choices.includes? v
          self
            .context
            .build_violation(constraint.multiple_message, NO_SUCH_CHOICE_ERROR, v)
            .add_parameter("{{ choices }}", choices)
            .invalid_value(v)
            .add

          return
        end
      end

      size = value.size

      if (limit = constraint.min) && (size < limit)
        self
          .context
          .build_violation(constraint.min_message, TOO_FEW_ERROR, value)
          .add_parameter("{{ limit }}", limit)
          .add_parameter("{{ choices }}", choices)
          .plural(limit.to_i)
          .invalid_value(value)
          .add

        return
      end

      if (limit = constraint.max) && (size > limit)
        self
          .context
          .build_violation(constraint.max_message, TOO_MANY_ERROR, value)
          .add_parameter("{{ limit }}", limit)
          .add_parameter("{{ choices }}", choices)
          .plural(limit.to_i)
          .invalid_value(value)
          .add

        return
      end
    end

    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Choice) : Nil
      return if value.nil?

      self.raise_invalid_type(value, "Enumerable") if constraint.multiple? && !value.is_a?(Enumerable)

      return if constraint.choices.includes? value

      self
        .context
        .build_violation(constraint.message, NO_SUCH_CHOICE_ERROR, value)
        .add_parameter("{{ choices }}", constraint.choices)
        .add
    end
  end
end
