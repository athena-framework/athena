require "./base_accept"

# Represents an [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5) header character set.
#
# ```
# accept = ANG::AcceptLanguage.new "zh-Hans-CN; q = 0.3; key=value"
#
# accept.header            # => "zh-Hans-CN; q = 0.3; key=value"
# accept.normalized_header # => "zh-Hans-CN; key=value"
# accept.parameters        # => {"key" => "value"}
# accept.quality           # => 0.3
# accept.language          # => "zh"
# accept.region            # => "cn"
# accept.script            # => "hans"
# ```
struct Athena::Negotiation::AcceptLanguage < Athena::Negotiation::BaseAccept
  # Returns the language for this `AcceptLanguage` header.
  # E.x. if the `#language_range` is `zh-Hans-CN`, the language would be `zh`.
  getter language : String

  # Returns the region, if any, for this `AcceptLanguage` header.
  # E.x. if the `#language_range` is `zh-Hans-CN`, the region would be `cn`
  getter region : String? = nil

  # Returns the script, if any, for this `AcceptLanguage` header.
  # E.x. if the `#language_range` is `zh-Hans-CN`, the script would be `hans`
  getter script : String? = nil

  def initialize(value : String)
    super value

    parts = @accept_value.split '-'

    case parts.size
    when 1
      @language = parts[0]
    when 2
      @language = parts[0]
      @region = parts[1]
    when 3
      @language = parts[0]
      @script = parts[1]
      @region = parts[2]
    else
      raise ANG::Exceptions::InvalidLanguage.new @accept_value
    end
  end

  # Returns the language range this `AcceptLanguage` header represents.
  #
  # I.e. `#header` minus the `#quality` and `#parameters`.
  def language_range : String
    @accept_value
  end
end
