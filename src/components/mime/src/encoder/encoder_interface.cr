module Athena::MIME::Encoder::EncoderInterface
  # Returns an encoded version of the provided *input*.
  #
  # *first_line_offset* may optionally be used depending on the exact implementation if the first line needs to be shorter.
  # *max_line_length* may optionally be used depending on the exact implementation to customize the max length of each line.
  abstract def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
end
