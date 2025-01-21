require "./content_encoder_interface"

require "base64"

# A content encoder based on the [Base64](https://datatracker.ietf.org/doc/html/rfc4648) spec.
struct Athena::MIME::Encoder::Base64Content
  include Athena::MIME::Encoder::ContentEncoderInterface

  # :inherit:
  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    Base64.encode input
  end

  # :inherit:
  def encode(input : IO, max_line_length : Int32? = nil) : String
    Base64.encode input
  end

  # :inherit:
  def name : String
    "base64"
  end
end
