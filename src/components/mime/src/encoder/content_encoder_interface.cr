require "./encoder_interface"

module Athena::MIME::Encoder::ContentEncoderInterface
  include Athena::MIME::Encoder::EncoderInterface

  abstract def encode(input : IO, max_line_length : Int32? = nil) : String
  abstract def name : String
end
