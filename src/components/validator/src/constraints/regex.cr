# Validates that a value matches a regular expression.
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ## Configuration
#
# ### Required Arguments
#
# #### pattern
#
# **Type:** `::Regex`
#
# The `::Regex` pattern that the value should match.
#
# ### Optional Arguments
#
# #### match
#
# **Type:** `Bool` **Default:** `true`
#
# If set to `false`, validation will require the value does _NOT_ match the [pattern](#pattern).
#
# #### message
#
# **Type:** `String` **Default:** `This value should match '{{ pattern }}'.`
#
# The message that will be shown if the value does not match the [pattern](#pattern).
#
# ##### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ pattern }}` - The regular expression pattern that the value should match.
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
class Athena::Validator::Constraints::Regex < Athena::Validator::Constraint
  REGEX_FAILED_ERROR = "108987a0-2d81-44a0-b8d4-1c7ab8815343"

  @@error_names = {
    REGEX_FAILED_ERROR => "REGEX_FAILED_ERROR",
  }

  getter pattern : ::Regex
  getter? match : Bool

  def initialize(
    @pattern : ::Regex,
    @match : Bool = true,
    message : String = "This value should match '{{ pattern }}'.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Regex) : Nil
      value = value.to_s

      return if value.nil? || value.empty?
      return unless constraint.match? ^ value.matches? constraint.pattern

      self
        .context
        .build_violation(constraint.message, REGEX_FAILED_ERROR, value)
        .add_parameter("{{ pattern }}", constraint.pattern)
        .add
    end
  end
end
