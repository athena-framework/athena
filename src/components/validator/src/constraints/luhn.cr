# Validates that a credit card number passes the [Luhn algorithm](https://en.wikipedia.org/wiki/Luhn_algorithm); a useful first step to validating a credit card.
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
# **Type:** `String` **Default:** `This value is not a valid credit card number.`
#
# The message that will be shown if the value is not pass the Luhn check.
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
class Athena::Validator::Constraints::Luhn < Athena::Validator::Constraint
  INVALID_CHARACTERS_ERROR = "c42b8d36-d9e9-4f5f-aad6-5190e27a1102"
  CHECKSUM_FAILED_ERROR    = "a4f089dd-fd63-4d50-ac30-34ed2a8dc9dd"

  @@error_names = {
    INVALID_CHARACTERS_ERROR => "INVALID_CHARACTERS_ERROR",
    CHECKSUM_FAILED_ERROR    => "CHECKSUM_FAILED_ERROR",
  }

  def initialize(
    message : String = "This value is not a valid credit card number.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Luhn) : Nil
      value = value.to_s

      return if value.nil? || value.empty?

      characters = value.chars

      unless characters.all? &.number?
        return self.context.add_violation constraint.message, INVALID_CHARACTERS_ERROR, value
      end

      last_dig : Int32 = characters.pop.to_i
      checksum : Int32 = (characters.reverse.map_with_index { |n, idx| val = idx.even? ? n.to_i * 2 : n.to_i; val -= 9 if val > 9; val }.sum + last_dig)

      return if !checksum.zero? && checksum.divisible_by?(10)

      self.context.add_violation constraint.message, CHECKSUM_FAILED_ERROR, value
    end
  end
end
