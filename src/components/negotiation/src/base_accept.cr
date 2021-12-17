# Base type for properties/logic all [Accept*](https://tools.ietf.org/html/rfc7231#section-5.3) headers share.
abstract struct Athena::Negotiation::BaseAccept
  # Returns the full unaltered header `self` represents.
  # E.x. `text/html`, `unicode-1-1;q=0.8`, or `zh-Hans-CN`.
  getter header : String

  # Returns a normalized version of the `#header`, excluding the `#quality` parameter.
  #
  # This includes removing extraneous whitespace, and alphabetizing the `#parameters`.
  getter normalized_header : String

  # Returns any extension parameters included in the header `self` represents.
  # E.x. `charset=UTF-8` or `version=2`.
  getter parameters : Hash(String, String) = Hash(String, String).new

  # Returns the [quality value](https://tools.ietf.org/html/rfc7231#section-5.3.1) of the header `self` represents.
  getter quality : Float32 = 1.0

  # Represents the base header value, e.g. `#header` minus the `#quality` and `#parameters`.
  # This is exposed as a getter on each subtype to have a more descriptive API.
  protected getter accept_value : String

  def initialize(@header : String)
    parts = @header.split ';'
    @accept_value = parts.shift.strip.downcase

    parts.each do |part|
      part = part.split '='

      # Skip invalid parameters
      next unless part.size == 2

      @parameters[part[0].strip.downcase] = part[1].strip(" \"")
    end

    if quality = @parameters.delete "q"
      # RFC Only allows max of 3 decimal points.
      @quality = quality.to_f32.round 3
    end

    @normalized_header = String.build do |io|
      io << @accept_value

      unless @parameters.empty?
        io << "; "
        @parameters.keys.sort!.join(io, "; ") { |k, join_io| join_io << "#{k}=#{@parameters[k]}" }
      end
    end
  end
end
