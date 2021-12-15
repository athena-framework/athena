# Validates that a value is a positive number, or `0`.
# Use `AVD::Constraints::Positive` if you don't want to allow `0`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value should be positive or zero.`
#
# The message that will be shown if the value is not greater than or equal to `0`.
#
# ##### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ compared_value }}` - The expected value.
# * `{{ compared_value_type }}` - The type of the expected value.
#
# #### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# #### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
class Athena::Validator::Constraints::PositiveOrZero < Athena::Validator::Constraints::GreaterThanOrEqual(Int32)
  def initialize(
    message : String = "This value should be positive or zero.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super Int32.zero, message, groups, payload
  end

  def validated_by : AVD::ConstraintValidator.class
    AVD::Constraints::GreaterThanOrEqual::Validator
  end
end
