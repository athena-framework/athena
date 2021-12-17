# Validates that a value is a valid IP address.
# By default validates the value as an `IPv4` address, but can be customized to validate `IPv6`s, or both.
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### version
#
# **Type:** `AVD::Constraints::IP::Version` **Default:** `AVD::Constraints::IP::Version::V4`
#
# Defines the pattern that should be used to validate the IP address.
#
# #### message
#
# **Type:** `String` **Default:** `This is not a valid IP address.`
#
# The message that will be shown if the value is not a valid IP address.
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
class Athena::Validator::Constraints::IP < Athena::Validator::Constraint
  # Determines _how_ the IP address should be validated.
  enum Version
    # Validates for `IPv4` addresses.
    V4

    # Validates for `IPv6` addresses.
    V6

    # Validates for `IPv4` or `IPv6` addresses.
    V4_V6

    # Returns the `::Regex` pattern for `self`.
    def pattern : ::Regex
      case self
      in .v4?    then self.v4_regex
      in .v6?    then self.v6_regex
      in .v4_v6? then ::Regex.union self.v4_regex, self.v6_regex
      end
    end

    private def v4_regex : ::Regex
      /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
    end

    private def v6_regex : ::Regex
      /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/
    end
  end

  INVALID_IP_ERROR = "326b0aa4-3871-404d-986d-fe3e6c82005c"

  @@error_names = {
    INVALID_IP_ERROR => "INVALID_IP_ERROR",
  }

  getter version : AVD::Constraints::IP::Version

  def initialize(
    @version : AVD::Constraints::IP::Version = :v4,
    message : String = "This value is not a valid IP address.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  struct Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::IP) : Nil
      value = value.to_s

      return if value.nil? || value.empty?
      return if value.matches? constraint.version.pattern

      self.context.add_violation constraint.message, INVALID_IP_ERROR, value
    end
  end
end
