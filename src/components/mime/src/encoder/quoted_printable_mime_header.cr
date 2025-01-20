require "./encoder_interface"

# A MIME header encoder based on the [Q](https://datatracker.ietf.org/doc/html/rfc2047#autoid-6) spec.
struct Athena::MIME::Encoder::QuotedPrintableMIMEHeader
  include Athena::MIME::Encoder::MIMEHeaderEncoderInterface
  include Athena::MIME::Encoder::EncoderInterface

  private ALLOWED_CHARS = begin
    allowed_bytes = [] of Char
    allowed_bytes.concat('a'..'z')
    allowed_bytes.concat('A'..'Z')
    allowed_bytes.concat('0'..'9')
    allowed_bytes.concat ['!', '*', '+', '-', '/']
    allowed_bytes.concat ['=', '\r', '\n'] # Not allowed as per spec, but don't want to modify them as they're handled elsewhere
end

  # :inherit:
  def name : String
    "Q"
  end

  # :inherit:
  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    string = AMIME::Encoder::QuotedPrintableContent
      .quoted_printable_encode(input)
      .each_char
      .join { |char| ALLOWED_CHARS.includes?(char) ? char : sprintf("=%02X", char.ord) }

    # TODO: Maybe refactor this logic into an alternate form of `.quoted_printable_encode`?
    string.gsub(
      /(?:=20)|(?:=\r\n)|[\? _\(\)\"#$%&',\.]/,
      {
        "=20"   => "_",
        "=\r\n" => "\r\n",
        " "     => "_",
      }
    )
  end
end
