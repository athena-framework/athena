# Validates that a value is not blank; meaning not equal to a blank string, an empty `Iterable`, `false`, or optionally `nil`.
#
# # Configuration
#
# ## Optional Arguments
#
# ### allow_nil
#
# **Type:** `Bool` **Default:** `false`
#
# If set to `true`, `nil` values are considered valid and will not trigger a violation.
#
# ### message
#
# **Type:** `String` **Default:** `This value should not be blank.`
#
# The message that will be shown if the value is blank.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
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
class Athena::Validator::Constraints::NotBlank < Athena::Validator::Constraint
  IS_BLANK_ERROR = "0d0c3254-3642-4cb0-9882-46ee5918e6e3"

  @@error_names = {
    IS_BLANK_ERROR => "IS_BLANK_ERROR",
  }

  getter? allow_nil : Bool

  def initialize(
    @allow_nil : Bool = false,
    message : String = "This value should not be blank.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : String?, constraint : AVD::Constraints::NotBlank) : Nil
      validate_value(value, constraint) do |v|
        v.blank?
      end
    end

    # :inherit:
    def validate(value : Bool?, constraint : AVD::Constraints::NotBlank) : Nil
      validate_value(value, constraint) do |v|
        v == false
      end
    end

    # :inherit:
    def validate(value : Iterable?, constraint : AVD::Constraints::NotBlank) : Nil
      validate_value(value, constraint) do |v|
        v.empty?
      end
    end

    private def validate_value(value : _, constraint : AVD::Constraints::NotBlank, & : -> Bool) : Nil
      return if value.nil? && constraint.allow_nil?

      if value.nil? || yield value
        self.context.add_violation constraint.message, IS_BLANK_ERROR, value
      end
    end
  end
end
