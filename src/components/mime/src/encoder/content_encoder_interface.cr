require "./encoder_interface"

# A more specialized version of `AMIME::Encoder::EncoderInterface` used to encode MIME message contents.
module Athena::MIME::Encoder::ContentEncoderInterface
  include Athena::MIME::Encoder::EncoderInterface

  # Returns an string representing the encoded contents of the provided *input* IO.
  # With lines optionally limited to *max_line_length*, depending on the underlying implementation.
  abstract def encode(input : IO, max_line_length : Int32? = nil) : String

  # Returns the name of this encoder for use within the `content-transfer-encoding` header.
  abstract def name : String
end
