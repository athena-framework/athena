# Validates that the `#size` of an `Indexable` value is between some minimum and maximum.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@emails : Array(String)); end
#
#   @[Assert::Count(1..5)]
#   property emails : Array(String)
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
# **Type:** `String` **Default:** `This collection should contain exactly {{ limit }} element.|This collection should contain exactly {{ limit }} elements.`
#
# The message that will be shown if min and max values are equal and the underlying collection’s count is not exactly this value.
# The message is pluralized depending on how many elements the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ count }}` - The current collection count
# * `{{ limit }}` - The exact expected collection count
#
# ### min_message
#
# **Type:** `String` **Default:** `This collection should contain {{ limit }} element or more.|This collection should contain {{ limit }} elements or more.`
#
# The message that will be shown if the underlying collection’s count is less than the min.
# The message is pluralized depending on how many elements the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ count }}` - The current collection count
# * `{{ limit }}` - The lower limit
#
# ### max_message
#
# **Type:** `String` **Default:** `This collection should contain {{ limit }} element or less.|This collection should contain {{ limit }} elements or less.`
#
# The message that will be shown if the underlying collection’s count is greater than the max.
# The message is pluralized depending on how many elements the underlying value has.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ count }}` - The current collection count
# * `{{ limit }}` - The upper limit
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
class Athena::Validator::Constraints::Count < Athena::Validator::Constraint
  TOO_FEW_ERROR         = "07f04a04-c346-4983-9868-602c62a5d0c1"
  TOO_MANY_ERROR        = "c35d873a-8095-4710-88d0-de68bce36055"
  NOT_EQUAL_COUNT_ERROR = "ee29a9b5-924b-42dd-a810-044c86803244"

  @@error_names = {
    TOO_FEW_ERROR         => "TOO_FEW_ERROR",
    TOO_MANY_ERROR        => "TOO_MANY_ERROR",
    NOT_EQUAL_COUNT_ERROR => "NOT_EQUAL_COUNT_ERROR",
  }

  getter min : Int32?
  getter max : Int32?
  getter min_message : String
  getter max_message : String
  getter exact_message : String

  def self.new(
    range : ::Range,
    min_message : String = "This collection should contain {{ limit }} element or more.|This collection should contain {{ limit }} elements or more.",
    max_message : String = "This collection should contain {{ limit }} element or less.|This collection should contain {{ limit }} elements or less.",
    exact_message : String = "This collection should contain exactly {{ limit }} element.|This collection should contain exactly {{ limit }} elements.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    new range.begin, range.end, min_message, max_message, exact_message, groups, payload
  end

  private def initialize(
    @min : Int32?,
    @max : Int32?,
    @min_message : String = "This collection should contain {{ limit }} element or more.|This collection should contain {{ limit }} elements or more.",
    @max_message : String = "This collection should contain {{ limit }} element or less.|This collection should contain {{ limit }} elements or less.",
    @exact_message : String = "This collection should contain exactly {{ limit }} element.|This collection should contain exactly {{ limit }} elements.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : Indexable, constraint : AVD::Constraints::Count) : Nil
      return if value.nil?

      count = value.size

      min = constraint.min
      max = constraint.max

      if max && count > max
        exactly_option_enabled = min == max

        self
          .context
          .build_violation(
            exactly_option_enabled ? constraint.exact_message : constraint.max_message,
            exactly_option_enabled ? NOT_EQUAL_COUNT_ERROR : TOO_MANY_ERROR,
            value
          )
          .add_parameter("{{ count }}", count)
          .add_parameter("{{ limit }}", max)
          .invalid_value(value)
          .plural(max)
          .add
      end

      if min && count < min
        exactly_option_enabled = min == max

        self
          .context
          .build_violation(
            exactly_option_enabled ? constraint.exact_message : constraint.min_message,
            exactly_option_enabled ? NOT_EQUAL_COUNT_ERROR : TOO_FEW_ERROR,
            value
          )
          .add_parameter("{{ count }}", count)
          .add_parameter("{{ limit }}", min)
          .invalid_value(value)
          .plural(min)
          .add
      end
    end
  end
end
