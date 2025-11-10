# Validates that the length of a `String` is between some minimum and maximum.
# Non `String` values are stringified via `#to_s`.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@username : String); end
#
#   @[Assert::Length(3..30)]
#   property username : String
# end
# ```
#
# # Configuration
#
# ## Required Arguments
#
# ### range
#
# **Type:** `::Range`
#
# The `::Range` that defines the minimum and maximum values, if any.
# An endless range can be used to only have a minimum or maximum.
#
# ## Optional Arguments
#
# NOTE: This constraint does not support a `message` argument.
#
# ### exact_message
#
# **Type:** `String` **Default:** `This value should have exactly {{ limit }} character.|This value should have exactly {{ limit }} characters.`
#
# The message that will be shown if min and max values are equal and the underlying value’s length is not exactly this value.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ limit }}` - The exact expected length.
# * `{{ value }}` - The current (invalid) value.
# * `{{ value_length }}` - The current value's length.
#
# ### min_message
#
# **Type:** `String` **Default:** `This value is too short. It should have {{ limit }} character or more.|This value is too short. It should have {{ limit }} characters or more.`
#
# The message that will be shown if the underlying value’s length is less than the min.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ limit }}` - The exact minimum length.
# * `{{ min }}` - The expected minimum length.
# * `{{ max }}` - The expected maximum length.
# * `{{ value }}` - The current (invalid) value.
# * `{{ value_length }}` - The current value's length.
#
# ### max_message
#
# **Type:** `String` **Default:** `This value is too long. It should have {{ limit }} character or less.|This value is too long. It should have {{ limit }} characters or less.`
#
# The message that will be shown if the underlying value’s length is greater than the max.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ limit }}` - The exact maximum length.
# * `{{ min }}` - The expected minimum length.
# * `{{ max }}` - The expected maximum length.
# * `{{ value }}` - The current (invalid) value.
# * `{{ value_length }}` - The current value's length.
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
class Athena::Validator::Constraints::Length < Athena::Validator::Constraint
  TOO_SHORT_ERROR        = "643f9d15-a5fd-41b7-b6d8-85f40855ba11"
  TOO_LONG_ERROR         = "e07eee2c-be7a-4ac3-be6b-2ea344250f99"
  NOT_EQUAL_LENGTH_ERROR = "03ef6899-6e39-4e7a-9ac9-5f4374736273"

  @@error_names = {
    TOO_SHORT_ERROR        => "TOO_SHORT_ERROR",
    TOO_LONG_ERROR         => "TOO_LONG_ERROR",
    NOT_EQUAL_LENGTH_ERROR => "NOT_EQUAL_LENGTH_ERROR",
  }

  getter min : Int32?
  getter max : Int32?
  getter min_message : String
  getter max_message : String
  getter exact_message : String

  def self.new(
    range : ::Range,
    min_message : String = "This value is too short. It should have {{ limit }} character or more.|This value is too short. It should have {{ limit }} characters or more.",
    max_message : String = "This value is too long. It should have {{ limit }} character or less.|This value is too long. It should have {{ limit }} characters or less.",
    exact_message : String = "This value should have exactly {{ limit }} character.|This value should have exactly {{ limit }} characters.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    new range.begin, range.end, min_message, max_message, exact_message, groups, payload
  end

  private def initialize(
    @min : Int32?,
    @max : Int32?,
    @min_message : String = "This value is too short. It should have {{ limit }} character or more.|This value is too short. It should have {{ limit }} characters or more.",
    @max_message : String = "This value is too long. It should have {{ limit }} character or less.|This value is too long. It should have {{ limit }} characters or less.",
    @exact_message : String = "This value should have exactly {{ limit }} character.|This value should have exactly {{ limit }} characters.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    # ameba:disable Metrics/CyclomaticComplexity
    def validate(value : _, constraint : AVD::Constraints::Length) : Nil
      return if value.nil?

      length = value.to_s.size

      min = constraint.min
      max = constraint.max

      if max && length > max
        exactly_option_enabled = min == max

        builder = self
          .context
          .build_violation(
            exactly_option_enabled ? constraint.exact_message : constraint.max_message,
            exactly_option_enabled ? NOT_EQUAL_LENGTH_ERROR : TOO_LONG_ERROR,
            value
          )

        if min
          builder.add_parameter("{{ min }}", min)
        end

        builder
          .add_parameter("{{ limit }}", max)
          .add_parameter("{{ max }}", max)
          .add_parameter("{{ value_length }}", length)
          .invalid_value(value)
          .plural(max)
          .add
      end

      if min && length < min
        exactly_option_enabled = min == max

        builder = self
          .context
          .build_violation(
            exactly_option_enabled ? constraint.exact_message : constraint.min_message,
            exactly_option_enabled ? NOT_EQUAL_LENGTH_ERROR : TOO_SHORT_ERROR,
            value
          )

        if max
          builder.add_parameter("{{ max }}", max)
        end

        builder
          .add_parameter("{{ limit }}", min)
          .add_parameter("{{ min }}", min)
          .add_parameter("{{ value_length }}", length)
          .invalid_value(value)
          .plural(min)
          .add
      end
    end
  end
end
