# Represents textual content a part of an email.
class Athena::MIME::Part::Text < Athena::MIME::Part::Abstract
  private DEFAULT_ENCODERS = ["quoted-printable", "base64", "8bit"]

  @@encoders = Hash(String, AMIME::Encoder::ContentEncoderInterface).new

  # Controls the `content-disposition` header value for this part.
  property disposition : String? = nil

  # Returns the name of this part.
  property name : String? = nil

  @body : String | IO | AMIME::Part::File
  protected setter encoding : String

  def initialize(
    body : String | IO | AMIME::Part::File,
    @charset : String? = "UTF-8",
    @sub_type : String = "plain",
    encoding : String? = nil,
  )
    if body.is_a? AMIME::Part::File
      if !::File::Info.readable?(body.path) || ::File.directory?(body.path)
        raise AMIME::Exception::InvalidArgument.new "File is not readable."
      end
    end

    @body = body

    if encoding
      raise AMIME::Exception::InvalidArgument.new "Unexpected encoding type" unless DEFAULT_ENCODERS.includes? encoding

      @encoding = encoding
    else
      @encoding = choose_encoding
    end
  end

  # :inherit:
  def media_type : String
    "text"
  end

  # :inherit:
  def media_sub_type : String
    @sub_type
  end

  protected def body_to_s(io : IO) : Nil
    io << self.encoder.encode self.body, @charset
  end

  # Returns the raw contents of this part as a string.
  # Use `#body_to_s` to get a properly encoded representation.
  def body : String
    case body = @body
    in AMIME::Part::File
      ::File.read body.path
    in String then body
    in IO
      body.rewind if body.responds_to? :rewind

      body.gets_to_end
    end
  end

  def prepared_headers : AMIME::Header::Collection
    headers = super

    headers.upsert "content-type", "#{self.media_type}/#{self.media_sub_type}", ->headers.add_parameterized_header(String, String)

    if charset = @charset
      headers.header_parameter "content-type", "charset", charset
    end

    if (name = @name.presence) && ("form-data" != @disposition)
      headers.header_parameter "content-type", "name", name
    end

    headers.upsert "content-transfer-encoding", @encoding, ->headers.add_text_header(String, String)

    if !headers.has_key?("content-disposition") && (disposition = @disposition)
      headers.upsert "content-disposition", disposition, ->headers.add_parameterized_header(String, String)

      if name = @name
        headers.header_parameter "content-disposition", "name", name
      end
    end

    headers
  end

  private def choose_encoding : String
    @charset.nil? ? "base64" : "quoted-printable"
  end

  private def encoder : AMIME::Encoder::ContentEncoderInterface
    case @encoding
    when "8bit"             then @@encoders[@encoding] ||= AMIME::Encoder::EightBitContent.new
    when "quoted-printable" then @@encoders[@encoding] ||= AMIME::Encoder::QuotedPrintableContent.new
    when "base64"           then @@encoders[@encoding] ||= AMIME::Encoder::Base64Content.new
    else
      @@encoders[@encoding]
    end
  end
end
