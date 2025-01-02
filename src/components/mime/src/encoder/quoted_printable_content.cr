struct Athena::MIME::Encoder::QuotedPrintableContent
  include Athena::MIME::Encoder::ContentEncoderInterface

  private MAX_LINE_LENGTH = 75

  # Encodes a string as per https://datatracker.ietf.org/doc/html/rfc2045#section-6.7.
  def self.quoted_printable_encode(string : String) : String
    # TODO: Refactor this to be more idiomatic.

    line_pos = 0

    String.build do |result|
      i = 0

      bytesize = string.bytesize
      bytes = string.bytes

      while i < bytesize
        c = bytes[i]

        if c == 0x0D && i + 1 < bytesize && bytes[i + 1] == 0x0A
          result << "\r\n"
          i += 2
          line_pos = 0
        else
          if c.chr.control? || c == 0x7F || c >= 0x80 || c == 0x3D || (c == 0x20 && i + 1 < bytesize && bytes[i + 1] == 0x0D)
            needs_line_break = false

            line_pos += 3
            if c <= 0x7F && (line_pos) > MAX_LINE_LENGTH
              needs_line_break = true
            elsif c > 0x7F && c <= 0xDF && ((line_pos + 3) > MAX_LINE_LENGTH)
              needs_line_break = true
            elsif c > 0xDF && c <= 0xEF && ((line_pos + 6) > MAX_LINE_LENGTH)
              needs_line_break = true
            elsif c > 0xEF && c <= 0xF4 && ((line_pos + 9) > MAX_LINE_LENGTH)
              needs_line_break = true
            end

            if needs_line_break
              result << "=\r\n"
              line_pos = 3
            end

            result << '='
            c.to_s result, base: 16, upcase: true, precision: 2
          else
            line_pos += 1
            if line_pos > MAX_LINE_LENGTH
              result << "=\r\n"
              line_pos = 1
            end
            result << c.chr
          end
          i += 1
        end
      end
    end
  end

  # :inherit:
  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    self.standardize self.class.quoted_printable_encode input
  end

  # :inherit:
  def encode(input : IO, max_line_length : Int32? = nil) : String
    self.encode input.gets_to_end
  end

  # :inherit:
  def name : String
    "quoted-printable"
  end

  private def standardize(string : String) : String
    # Transform CR or LF to CRLF
    string = string.gsub /0D(?!=0A)|(?<!=0D)=0A/, "=0D=0A"

    # Transform =0D=0A to CRLF
    string = string
      .gsub("\t=0D=0A", "=09\r\n")
      .gsub(" =0D=0A", "=20\r\n")
      .gsub("=0D=0A", "\r\n")

    return string if string.empty?

    case last_char = string[-1].ord
    when 0x09 then string.sub(-1, "=09")
    when 0x20 then string.sub(-1, "=20")
    else
      string
    end
  end
end
