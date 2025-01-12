require "./content_encoder_interface"

struct Athena::MIME::Encoder::EightBitContent
  include Athena::MIME::Encoder::ContentEncoderInterface

  # :inherit:
  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    input
  end

  # :inherit:
  def encode(input : IO, max_line_length : Int32? = nil) : String
    input.gets_to_end
  end

  # :inherit:
  def name : String
    "8bit"
  end
end
