# Validates that a value is a valid email address.
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### mode
#
# **Type:** `AVD::Constraints::Email::Mode` **Default:** `AVD::Constraints::Email::Mode::Loose`
#
# Defines the pattern that should be used to validate the email address.
#
# #### message
#
# **Type:** `String` **Default:** `This value is not a valid email address.`
#
# The message that will be shown if the value is not a valid email address.
#
# ##### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
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
class Athena::Validator::Constraints::Email < Athena::Validator::Constraint
  # Determines _how_ the email address should be validated.
  enum Mode
    # Validates the email against a simple `::Regex` that allows all values with an `@` symbol and a `.` in the host part of the email address.
    Loose

    # Validates the email against the [HTML5 input pattern](https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address).
    HTML5

    # TODO: Implement this mode.
    # STRICT

    # Returns the `::Regex` pattern for `self`.
    def pattern : ::Regex
      case self
      in .html5? then /^[a-zA-Z0-9.!\#$\%&\'*+\\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/
      in .loose? then /^.+\@\S+\.\S+$/
      end
    end
  end

  INVALID_FORMAT_ERROR = "ad9d877d-9ad1-4dd7-b77b-e419934e5910"

  @@error_names = {
    INVALID_FORMAT_ERROR => "INVALID_FORMAT_ERROR",
  }

  getter mode : AVD::Constraints::Email::Mode

  def initialize(
    @mode : AVD::Constraints::Email::Mode = :loose,
    message : String = "This value is not a valid email address.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  struct Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Email) : Nil
      value = value.to_s

      return if value.nil? || value.empty?
      return if value.matches? constraint.mode.pattern

      self.context.add_violation constraint.message, INVALID_FORMAT_ERROR, value
    end
  end
end
