require "./text"

# Represents attached/embedded content within the MIME message.
class Athena::MIME::Part::Data < Athena::MIME::Part::Text
  # Creates the part using the contents the file at the provided *path* as the body, optionally with the provided *name* and *content_type*.
  # The file is lazily read.
  def self.from_path(path : String | Path, name : String? = nil, content_type : String? = nil) : self
    new AMIME::Part::File.new(path), name, content_type
  end

  # Returns the media type of this part based on its body.
  getter media_type : String

  # Returns the name of the file associated with this part.
  getter filename : String?
  @content_id : String?

  def initialize(
    body : String | IO | AMIME::Part::File,
    filename : String? = nil,
    content_type : String? = nil,
    encoding : String? = nil,
  )
    if body.is_a?(AMIME::Part::File) && filename.nil?
      filename = body.filename
    end

    content_type ||= body.is_a?(AMIME::Part::File) ? body.content_type : "application/octet-stream"

    @media_type, sub_type = content_type.split '/'

    super body, nil, sub_type, encoding

    if filename
      @filename = filename
      self.name = filename
    end

    self.disposition = "attachment"
  end

  # :inherit:
  def prepared_headers : AMIME::Header::Collection
    headers = super

    if cid = @content_id
      headers.upsert "content-id", cid, ->headers.add_id_header(String, String)
    end

    if name = @filename
      headers.header_parameter "content-disposition", "filename", name
    end

    headers
  end

  # Marks this part as representing embedded content versus an attached file.
  def as_inline : self
    self.disposition = "inline"

    self
  end

  # Sets the content ID of this part to the provided *id*.
  def content_id=(id : String) : self
    if !id.includes? '@'
      raise AMIME::Exception::InvalidArgument.new "The '#{id}' CID is invalid as it does not contain an '@' symbol."
    end

    @content_id = id

    self
  end

  # Returns the content type of this part.
  def content_type : String
    "#{self.media_type}/#{self.media_sub_type}"
  end

  # Returns the content ID of this part, generating a unique one if one was not already set.
  def content_id : String
    @content_id ||= self.generate_content_id
  end

  # Returns `true` if this part has a `#content_id` currently set.
  def has_content_id? : Bool
    !@content_id.nil?
  end

  private def generate_content_id : String
    "#{Random::Secure.hex(16)}@athena"
  end
end
