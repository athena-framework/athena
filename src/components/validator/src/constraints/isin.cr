# Validates that a value is a valid [International Securities Identification Number (ISIN)](https://en.wikipedia.org/wiki/International_Securities_Identification_Number).
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value is not a valid International Securities Identification Number (ISIN).`
#
# The message that will be shown if the value is not a valid ISIN.
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
class Athena::Validator::Constraints::ISIN < Athena::Validator::Constraint
  INVALID_LENGTH_ERROR   = "1d1c3fbe-5b6f-42be-afa5-6840655865da"
  INVALID_PATTERN_ERROR  = "0b6ba8c4-b6aa-44dc-afac-a6f7a9a2556d"
  INVALID_CHECKSUM_ERROR = "c7d37ffb-0273-4f57-91f7-f47bf49aad08"

  private VALIDATION_LENGTH  = 12
  private VALIDATION_PATTERN = /[A-Z]{2}[A-Z0-9]{9}[0-9]{1}/

  @@error_names = {
    INVALID_LENGTH_ERROR   => "INVALID_LENGTH_ERROR",
    INVALID_PATTERN_ERROR  => "INVALID_PATTERN_ERROR",
    INVALID_CHECKSUM_ERROR => "INVALID_CHECKSUM_ERROR",
  }

  def initialize(
    message : String = "This value is not a valid International Securities Identification Number (ISIN).",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  struct Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::ISIN) : Nil
      value = value.to_s

      return if value.nil? || value.empty?

      value = value.upcase

      if VALIDATION_LENGTH != value.size
        return self.context.add_violation constraint.message, INVALID_LENGTH_ERROR, value
      end

      unless value.matches? VALIDATION_PATTERN
        return self.context.add_violation constraint.message, INVALID_PATTERN_ERROR, value
      end

      return if self.is_correct_checksum value

      self.context.add_violation constraint.message, INVALID_CHECKSUM_ERROR, value
    end

    private def is_correct_checksum(isin : String) : Bool
      number = isin.chars.join &.to_i 36
      self.context.validator.validate(number, AVD::Constraints::Luhn.new).empty?
    end
  end
end
