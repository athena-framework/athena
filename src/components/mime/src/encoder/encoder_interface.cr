module Athena::MIME::Encoder::EncoderInterface
  abstract def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
end
