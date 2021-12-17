require "./base_accept"

# Represents an [Accept-Charset](https://tools.ietf.org/html/rfc7231#section-5.3.3) header character set.
#
# ```
# accept = ANG::AcceptCharset.new "iso-8859-1; q = 0.5; key=value"
#
# accept.header            # => "iso-8859-1; q = 0.5; key=value"
# accept.normalized_header # => "iso-8859-1; key=value"
# accept.parameters        # => {"key" => "value"}
# accept.quality           # => 0.5
# accept.charset           # => "iso-8859-1"
# ```
struct Athena::Negotiation::AcceptCharset < Athena::Negotiation::BaseAccept
  # Returns the character set this `AcceptCharset` header represents.
  #
  # I.e. `#header` minus the `#quality` and `#parameters`.
  def charset : String
    @accept_value
  end
end
