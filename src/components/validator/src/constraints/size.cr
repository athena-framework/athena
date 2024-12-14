# Validates that the `#size` of a `String` or `Indexable` value is between some minimum and maximum.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@username : String); end
#
#   @[Assert::Size(3..30)]
#   property username : String
# end
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
# **Type:** `String` **Default:** `This value should have exactly {{ limit }} {{ type }}.|This value should have exactly {{ limit }} {{ type }}s.`
#
# The message that will be shown if min and max values are equal and the underlying value’s size is not exactly this value.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ limit }}` - The exact expected size.
# * `{{ type }}` - `character` if the value is a string or `item` if the value is an indexable.
#
# ### min_message
#
# **Type:** `String` **Default:** `This value is too short. It should have {{ limit }} {{ type }} or more.|This value is too short. It should have {{ limit }} {{ type }}s or more.`
#
# The message that will be shown if the underlying value’s size is less than the min.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ limit }}` - The expected minimum size.
# * `{{ type }}` - `character` if the value is a string or `item` if the value is an indexable.
#
# ### max_message
#
# **Type:** `String` **Default:** `This value is too long. It should have {{ limit }} {{ type }} or less.|This value is too long. It should have {{ limit }} {{ type }}s or less.`
#
# The message that will be shown if the underlying value’s size is greater than the max.
# The message is pluralized depending on how many elements/characters the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ limit }}` - The expected minimum size.
# * `{{ type }}` - `character` if the value is a string or `item` if the value is an indexable.
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
class Athena::Validator::Constraints::Size < Athena::Validator::Constraint
  TOO_SHORT_ERROR = "8ba31c71-1b37-4b76-8bc9-66896589b01f"
  TOO_LONG_ERROR  = "a1fa7a63-ea3b-46a0-adcc-5e1bcc26f73a"

  @@error_names = {
    TOO_SHORT_ERROR => "TOO_SHORT_ERROR",
    TOO_LONG_ERROR  => "TOO_LONG_ERROR",
  }

  getter min : Int32?
  getter max : Int32?
  getter min_message : String
  getter max_message : String
  getter exact_message : String

  def self.new(
    range : ::Range,
    min_message : String = "This value is too short. It should have {{ limit }} {{ type }} or more.|This value is too short. It should have {{ limit }} {{ type }}s or more.",
    max_message : String = "This value is too long. It should have {{ limit }} {{ type }} or less.|This value is too long. It should have {{ limit }} {{ type }}s or less.",
    exact_message : String = "This value should have exactly {{ limit }} {{ type }}.|This value should have exactly {{ limit }} {{ type }}s.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    new range.begin, range.end, min_message, max_message, exact_message, groups, payload
  end

  private def initialize(
    @min : Int32?,
    @max : Int32?,
    @min_message : String = "This value is too short. It should have {{ limit }} {{ type }} or more.|This value is too short. It should have {{ limit }} {{ type }}s or more.",
    @max_message : String = "This value is too long. It should have {{ limit }} {{ type }} or less.|This value is too long. It should have {{ limit }} {{ type }}s or less.",
    @exact_message : String = "This value should have exactly {{ limit }} {{ type }}.|This value should have exactly {{ limit }} {{ type }}s.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : String | Indexable, constraint : AVD::Constraints::Size) : Nil
      return if value.nil?

      size = value.size

      min = constraint.min
      max = constraint.max

      if max && size > max
        self
          .context
          .build_violation(min == max ? constraint.exact_message : constraint.max_message, TOO_LONG_ERROR, value)
          .add_parameter("{{ limit }}", max)
          .add_parameter("{{ type }}", value.is_a?(String) ? "character" : "item")
          .invalid_value(value)
          .plural(max)
          .add
      end

      if min && size < min
        self
          .context
          .build_violation(min == max ? constraint.exact_message : constraint.min_message, TOO_SHORT_ERROR, value)
          .add_parameter("{{ limit }}", min)
          .add_parameter("{{ type }}", value.is_a?(String) ? "character" : "item")
          .invalid_value(value)
          .plural(min)
          .add
      end
    end
  end
end
