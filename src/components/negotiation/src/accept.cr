require "./base_accept"

# Represents an [Accept](https://tools.ietf.org/html/rfc7231#section-5.3.2) header media type.
#
# ```
# accept = ANG::Accept.new "application/json; q = 0.75; charset = utf-8"
#
# accept.header            # => "application/json; q = 0.75; charset = utf-8"
# accept.normalized_header # => "application/json; charset=utf-8"
# accept.parameters        # => {"charset" => "utf-8"}
# accept.quality           # => 0.75
# accept.type              # => "application"
# accept.sub_type          # => "json"
# ```
struct Athena::Negotiation::Accept < Athena::Negotiation::BaseAccept
  # Returns the type for this `Accept` header.
  # E.x. if the `#media_range` is `application/json`, the type would be `application`.
  getter type : String

  # Returns the sub type for this `Accept` header.
  # E.x. if the `#media_range` is `application/json`, the sub type would be `json`.
  getter sub_type : String

  def initialize(value : String)
    super value

    @accept_value = "*/*" if @accept_value == "*"

    parts = @accept_value.split '/'

    if parts.size != 2 || !parts[0].presence || !parts[1].presence
      raise ANG::Exception::InvalidMediaType.new @accept_value
    end

    @type = parts[0]
    @sub_type = parts[1]
  end

  # Returns the media range this `Accept` header represents.
  #
  # I.e. `#header` minus the `#quality` and `#parameters`.
  def media_range : String
    @accept_value
  end
end
