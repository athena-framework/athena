require "./encoder_interface"

struct Athena::MIME::Encoder::QuotedPrintableMIMEHeader
  include Athena::MIME::Encoder::MIMEHeaderEncoderInterface
  include Athena::MIME::Encoder::EncoderInterface

  def name : String
    "Q"
  end

  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    string = AMIME::Encoder::QuotedPrintableContent.quoted_printable_encode input

    string
      .gsub(" ", "_")
      .gsub("=20", "_")
      .gsub("=\r\n", "\r\n")
  end
end
