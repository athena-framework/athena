require "./base_accept"

# Represents an [Accept-Encoding](https://tools.ietf.org/html/rfc7231#section-5.3.4) header character set.
#
# ```
# accept = ANG::AcceptEncoding.new "gzip; q = 0.5; key=value"
#
# accept.header            # => "gzip; q = 0.5; key=value"
# accept.normalized_header # => "gzip; key=value"
# accept.parameters        # => {"key" => "value"}
# accept.quality           # => 0.5
# accept.coding            # => "gzip"
# ```
struct Athena::Negotiation::AcceptEncoding < Athena::Negotiation::BaseAccept
  # Returns the content coding this `AcceptEncoding` header represents.
  #
  # I.e. `#header` minus the `#quality` and `#parameters`.
  def coding : String
    @accept_value
  end
end
