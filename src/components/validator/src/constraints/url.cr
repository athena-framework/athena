# Validates that a value is a valid URL string.
# The underlying value is converted to a string via `#to_s` before being validated.
#
# NOTE: As with most other constraints, `nil` and empty strings are considered valid values, in order to allow the value to be optional.
# If the value is required, consider combining this constraint with `AVD::Constraints::NotBlank`.
#
# ```
# class Profile
#   include AVD::Validatable
#
#   def initialize(@avatar_url : String); end
#
#   @[Assert::URL]
#   property avatar_url : String
# end
# ```
#
# # Configuration
#
# ## Optional Arguments
#
# ### protocols
#
# **Type:** `Array(String)` **Default:** `["http", "https"]`
#
# The protocols considered to be valid for the URL.
#
# ### relative_protocol
#
# **Type:** `Bool` **Default:** `false`
#
# If `true` the protocol is considered optional.
#
# ### require_tld
#
# **Type:** `Bool` **Default:** `true`
#
# The [URL spec](https://datatracker.ietf.org/doc/html/rfc1738) considers URLs like `https://aaa` or `https://foobar` to be valid
# However, this is most likely not desirable for most use cases.
# As such, this argument defaults to `true` and can be used to require that the host part of the URL will have to include a TLD (top-level domain name).
# E.g. `https://example.com` is valid but `https://example` is not.
#
# NOTE: This constraint does _NOT_ validate that the provided TLD is a valid one according to the [official list](https://en.wikipedia.org/wiki/List_of_Internet_top-level_domains).
#
# ### tld_message
#
# **Type:** `String` **Default:** `This URL is missing a top-level domain.`
#
# The message that will be shown if `#require_tld?` is `true` and the URL does not contain at least one TLD.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
#
# ### message
#
# **Type:** `String` **Default:** `This value is not a valid URL.`
#
# The message that will be shown if the URL is not valid.
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
class Athena::Validator::Constraints::URL < Athena::Validator::Constraint
  INVALID_URL_ERROR = "e87ceba6-a896-4906-9957-b102045272ee"
  MISSING_TLD_ERROR = "4507f4cc-90fd-4616-989b-2166fc0d1083"

  @@error_names = {
    INVALID_URL_ERROR => "INVALID_URL_ERROR",
    MISSING_TLD_ERROR => "MISSING_TLD_ERROR",
  }

  getter protocols : Array(String)
  getter? relative_protocol : Bool
  getter? require_tld : Bool
  getter tld_message : String

  def initialize(
    @protocols : Array(String) = ["http", "https"],
    @relative_protocol : Bool = false,
    @require_tld : Bool = true,
    @tld_message : String = "This URL is missing a top-level domain.",
    message : String = "This value is not a valid URL.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::URL) : Nil
      value = value.to_s

      return if value.nil? || value.empty?
      unless value.matches? self.pattern(constraint)
        self.context.add_violation constraint.message, INVALID_URL_ERROR, value
      end

      return unless constraint.require_tld?
      return unless url_host = URI.parse(value).host

      # URL with a TLD must include at least a `.`, but cannot be an IP address
      if !url_host.includes?('.') || Socket::IPAddress.valid?(url_host)
        self.context.add_violation constraint.tld_message, MISSING_TLD_ERROR, value
      end
    end

    def pattern(constraint : AVD::Constraints::URL) : ::Regex
      /^#{constraint.relative_protocol? ? "(?:(#{constraint.protocols.join('|')}):)?" : "(#{constraint.protocols.join('|')}):"}\/\/(((?:[\_\.\pL\pN-]|\%[0-9A-Fa-f]{2})+:)?((?:[\_\.\pL\pN-]|\%[0-9A-Fa-f]{2})+)@)?(([\pL\pN\pS\-\_\.])+(\.?([\pL\pN]|xn\-\-[\pL\pN-]+)+\.?)|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){6})(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:::(?:(?:(?:[0-9a-f]{1,4})):){5})(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:[0-9a-f]{1,4})))?::(?:(?:(?:[0-9a-f]{1,4})):){4})(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,1}(?:(?:[0-9a-f]{1,4})))?::(?:(?:(?:[0-9a-f]{1,4})):){3})(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,2}(?:(?:[0-9a-f]{1,4})))?::(?:(?:(?:[0-9a-f]{1,4})):){2})(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,3}(?:(?:[0-9a-f]{1,4})))?::(?:(?:[0-9a-f]{1,4})):)(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,4}(?:(?:[0-9a-f]{1,4})))?::)(?:(?:(?:(?:(?:[0-9a-f]{1,4})):(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,5}(?:(?:[0-9a-f]{1,4})))?::)(?:(?:[0-9a-f]{1,4})))|(?:(?:(?:(?:(?:(?:[0-9a-f]{1,4})):){0,6}(?:(?:[0-9a-f]{1,4})))?::))))\])(:[0-9]+)?(?:\/ (?:[\pL\pN\-._\~!$&\'()*+,;=:@]|\%[0-9A-Fa-f]{2})* )*(?:\? (?:[\pL\pN\-._\~!$&\'[\]()*+,;=:@\/?]|\%[0-9A-Fa-f]{2})* )?(?:\# (?:[\pL\pN\-._\~!$&\'()*+,;=:@\/?]|\%[0-9A-Fa-f]{2})* )?$/ix
    end
  end
end
