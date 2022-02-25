# Validates that a value is a valid [International Standard Serial Number (ISSN)](https://en.wikipedia.org/wiki/Issn).
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### case_sensitive
#
# **Type:** `Bool` **Default:** `false`
#
# The validator will allow ISSN values to end with a lowercase `x` by default.
# When set to `true`, this requires an uppcase case `X`.
#
# #### require_hypen
#
# **Type:** `Bool` **Default:** `false`
#
# The validator will allow non hyphenated values by default.
# When set to `true`, this requires a hyphenated ISSN value.
#
# #### message
#
# **Type:** `String` **Default:** `This value is not a valid International Standard Serial Number (ISSN).`
#
# The message that will be shown if the value is not a valid ISSN.
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
class Athena::Validator::Constraints::ISSN < Athena::Validator::Constraint
  TOO_SHORT_ERROR          = "85c5d3aa-fd0a-4cd0-8cf7-e014e6379d59"
  TOO_LONG_ERROR           = "fab8e3ea-2f77-4da7-b40f-d9b24ff8c0cc"
  MISSING_HYPHEN_ERROR     = "d6c120a9-0b56-4e45-b4bc-7fd186f2cfbd"
  INVALID_CHARACTERS_ERROR = "85c5d3aa-fd0a-4cd0-8cf7-e014e6379d59"
  INVALID_CASE_ERROR       = "66f892f3-9eed-4176-b823-0dafde72202a"
  CHECKSUM_FAILED_ERROR    = "62c01bab-fe8f-4072-aac8-aa4bdcde8361"

  @@error_names = {
    TOO_SHORT_ERROR          => "TOO_SHORT_ERROR",
    TOO_LONG_ERROR           => "TOO_LONG_ERROR",
    MISSING_HYPHEN_ERROR     => "MISSING_HYPHEN_ERROR",
    INVALID_CHARACTERS_ERROR => "INVALID_CHARACTERS_ERROR",
    INVALID_CASE_ERROR       => "INVALID_CASE_ERROR",
    CHECKSUM_FAILED_ERROR    => "CHECKSUM_FAILED_ERROR",
  }

  getter? case_sensitive : Bool
  getter? require_hypen : Bool

  def initialize(
    @case_sensitive : Bool = false,
    @require_hypen : Bool = false,
    message : String = "This value is not a valid International Standard Serial Number (ISSN).",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::ISSN) : Nil
      value = value.to_s

      return if value.nil? || value.empty?

      canonical = value

      if canonical[4]? == '-'
        canonical = canonical.delete '-'
      elsif constraint.require_hypen?
        return self.context.add_violation constraint.message, MISSING_HYPHEN_ERROR, value
      end

      self.validate_size canonical do |code|
        return self.context.add_violation constraint.message, code, value
      end

      char = self.validate_characters canonical do
        return self.context.add_violation constraint.message, INVALID_CHARACTERS_ERROR, value
      end

      if constraint.case_sensitive? && char == 'x'
        return self.context.add_violation constraint.message, INVALID_CASE_ERROR, value
      end

      self.validate_checksum char, canonical do
        self.context.add_violation constraint.message, CHECKSUM_FAILED_ERROR, value
      end
    end

    private def validate_size(issn : String, & : String ->) : Nil
      yield TOO_SHORT_ERROR if issn.size < 8
      yield TOO_LONG_ERROR if issn.size > 8
    end

    private def validate_characters(issn : String, &) : Char
      yield unless issn[...7].each_char.all? &.number?
      yield if (char = issn[7]) && !char.number? && !char.in? 'x', 'X'

      char
    end

    private def validate_checksum(char : Char, issn : String, &) : Nil
      checksum = char.in?('x', 'X') ? 10 : char.to_i

      7.times do |idx|
        checksum += (8 - idx) * issn[idx].to_i
      end

      yield unless checksum.divisible_by? 11
    end
  end
end
