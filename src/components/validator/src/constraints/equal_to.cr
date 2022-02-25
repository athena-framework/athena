# Validates that a value is equal to another.
#
# ## Configuration
#
# ### Required Arguments
#
# #### value
#
# Defines the value that the value being validated should be compared to.
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value should be equal to {{ compared_value }}.`
#
# The message that will be shown if the value is not equal to the comparison value.
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
class Athena::Validator::Constraints::EqualTo(ValueType) < Athena::Validator::Constraint
  include Athena::Validator::Constraints::AbstractComparison(ValueType)

  NOT_EQUAL_ERROR = "47d83d11-15d5-4267-b469-1444f80fd169"

  @@error_names = {
    NOT_EQUAL_ERROR => "NOT_EQUAL_ERROR",
  }

  # :inherit:
  def default_error_message : String
    "This value should be equal to {{ compared_value }}."
  end

  class Validator < Athena::Validator::Constraints::ComparisonValidator
    # :inherit:
    def compare_values(actual : _, expected : _) : Bool
      actual == expected
    end

    # :inherit:
    def error_code : String
      NOT_EQUAL_ERROR
    end
  end
end
