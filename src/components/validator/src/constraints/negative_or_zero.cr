# Validates that a value is a negative number, or `0`.
# Use `AVD::Constraints::Negative` if you don't want to allow `0`.
#
# ```
# class Mall
#   include AVD::Validatable
#
#   def initialize(@lowest_floor : Number); end
#
#   @[Assert::NegativeOrZero]
#   property lowest_floor : Number
# end
# ```
#
# # Configuration
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This value should be negative or zero.`
#
# The message that will be shown if the value is not less than or equal to `0`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ compared_value }}` - The expected value.
# * `{{ compared_value_type }}` - The type of the expected value.
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
# The `AVD::Constraint@payload` is not used by `Athena::Validator`, but its processing is completely up to you
class Athena::Validator::Constraints::NegativeOrZero < Athena::Validator::Constraints::LessThanOrEqual(Int32)
  def initialize(
    message : String = "This value should be negative or zero.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super Int32.zero, message, groups, payload
  end

  def validated_by : AVD::ConstraintValidator.class
    AVD::Constraints::LessThanOrEqual::Validator
  end
end
