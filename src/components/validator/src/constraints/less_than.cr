# Validates that a value is less than another.
#
# ## Configuration
#
# ### Required Arguments
#
# #### value
#
# **Type:** `Number | String | Time`
#
# Defines the value that the value being validated should be compared to.
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value should be less than {{ compared_value }}.`
#
# The message that will be shown if the value is not less than the comparison value.
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
class Athena::Validator::Constraints::LessThan(ValueType) < Athena::Validator::Constraint
  include Athena::Validator::Constraints::AbstractComparison(ValueType)

  TOO_HIGH_ERROR = "d9fbedb3-c576-45b5-b4dc-996030349bbf"

  @@error_names = {
    TOO_HIGH_ERROR => "TOO_HIGH_ERROR",
  }

  def default_error_message : String
    "This value should be less than {{ compared_value }}."
  end

  struct Validator < Athena::Validator::Constraints::ComparisonValidator
    def compare_values(actual : Number, expected : Number) : Bool
      actual < expected
    end

    def compare_values(actual : String, expected : String) : Bool
      actual < expected
    end

    def compare_values(actual : Time, expected : Time) : Bool
      actual < expected
    end

    # :inherit:
    def compare_values(actual : _, expected : _) : NoReturn
      # TODO: Support checking if arbitrarily typed values are actually comparable once `#responds_to?` supports it.
      self.raise_invalid_type actual, "Number | String | Time"
    end

    # :inherit:
    def error_code : String
      TOO_HIGH_ERROR
    end
  end
end
