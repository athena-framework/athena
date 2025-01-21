# Provides a high-level API for creating an email.
#
# ```
# email = AMIME::Email
#   .new
#   .from("me@example.com")
#   .to("you@example.com")
#   .cc("them@example.com")
#   .bcc("other@example.com")
#   .reply_to("me@example.com")
#   .priority(:high)
#   .subject("Important Notification")
#   .text("Lorem ipsum...")
#   .html("<h1>Lorem ipsum</h1> <p>...</p>")
#   .attach_from_path("/path/to/file.pdf", "my-attachment.pdf")
#   .embed_from_path("/path/to/logo.png")
#
# # ...
# ```
class Athena::MIME::Email < Athena::MIME::Message
  enum Priority
    HIGHEST = 1
    HIGH
    NORMAL
    LOW
    LOWEST

    # :nodoc:
    def to_s : String
      "#{self.value} (#{super.titleize})"
    end
  end

  @text : IO | String | Nil = nil

  # Returns the charset of the `#text_body` for this email.
  getter text_charset : String? = nil

  @html : IO | String | Nil = nil

  # Returns the charset of the `#html_body` for this email.
  getter html_charset : String? = nil

  # Returns an array of `AMIME::Part::Data` representing the email's attachments.
  getter attachments : Array(AMIME::Part::Data) = Array(AMIME::Part::Data).new

  # Used to avoid wrong body hash in DKIM signatures with multiple parts (e.g. HTML + TEXT) due to multiple boundaries.
  @cached_body : AMIME::Part::Abstract? = nil

  # :nodoc:
  def ==(other : self)
    {% if @type.class? %}
      return true if same?(other)
    {% end %}
    {% for field in @type.instance_vars %}
      return false unless @{{field.id}} == other.@{{field.id}}
    {% end %}
    true
  end

  # Returns the subject of this email, or `nil` if none is set.
  def subject : String?
    if header = @headers["subject"]?
      return header.body.as String
    end
  end

  # Sets the subject of this email to the provided *subject*.
  def subject(subject : String) : self
    @headers.upsert "subject", subject, ->@headers.add_text_header(String, String)

    self
  end

  # Returns the date of this email, or `nil` if none is set.
  def date : Time?
    if header = @headers["date"]?
      return header.body.as Time
    end
  end

  # Sets the date of this email to the provided *date*.
  def date(date : Time) : self
    @headers.upsert "date", date, ->@headers.add_date_header(String, Time)

    self
  end

  # Returns the return path of this email, or `nil` if none is set.
  def return_path : AMIME::Address?
    if header = @headers["return-path"]?
      return header.body.as AMIME::Address
    end
  end

  # Sets the return path of this email to the provided *address*.
  def return_path(address : AMIME::Address | String) : self
    @headers.upsert "return-path", AMIME::Address.create(address), ->@headers.add_path_header(String, AMIME::Address)

    self
  end

  # Returns the sender of this email, or `nil` if none is set.
  def sender : AMIME::Address?
    if header = @headers["sender"]?
      return header.body.as AMIME::Address
    end
  end

  # Sets the sender of this email to the provided *address*.
  def sender(address : AMIME::Address | String) : self
    @headers.upsert "sender", AMIME::Address.create(address), ->@headers.add_mailbox_header(String, AMIME::Address)

    self
  end

  # Returns the from addresses of this email, or an empty array if none were set.
  def from : Array(AMIME::Address)
    if header = @headers["from"]?
      return header.body.as(Array(AMIME::Address)).dup
    end

    [] of AMIME::Address
  end

  # Sets the from addresses of this email to the provided *addresses*, overriding any previously added ones.
  def from(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "from", addresses
  end

  # Appends the provided *addresses* to the list of current from addresses.
  def add_from(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "from", addresses
  end

  # Returns the reply-to addresses of this email, or an empty array if none were set.
  def reply_to : Array(AMIME::Address)
    if header = @headers["reply-to"]?
      return header.body.as(Array(AMIME::Address)).dup
    end

    [] of AMIME::Address
  end

  # Sets the reply-to addresses of this email to the provided *addresses*, overriding any previously added ones.
  def reply_to(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "reply-to", addresses
  end

  # Appends the provided *addresses* to the list of current reply-to addresses.
  def add_reply_to(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "reply-to", addresses
  end

  # Returns the to addresses of this email, or an empty array if none were set.
  def to : Array(AMIME::Address)
    if header = @headers["to"]?
      return header.body.as(Array(AMIME::Address)).dup
    end

    [] of AMIME::Address
  end

  # Sets the to addresses of this email to the provided *addresses*, overriding any previously added ones.
  def to(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "to", addresses
  end

  # Appends the provided *addresses* to the list of current to addresses.
  def add_to(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "to", addresses
  end

  # Returns the cc addresses of this email, or an empty array if none were set.
  def cc : Array(AMIME::Address)
    if header = @headers["cc"]?
      return header.body.as(Array(AMIME::Address)).dup
    end

    [] of AMIME::Address
  end

  # Sets the cc addresses of this email to the provided *addresses*, overriding any previously added ones.
  def cc(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "cc", addresses
  end

  # Appends the provided *addresses* to the list of current cc addresses.
  def add_cc(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "cc", addresses
  end

  # Returns the bcc addresses of this email, or an empty array if none were set.
  def bcc : Array(AMIME::Address)
    if header = @headers["bcc"]?
      return header.body.as(Array(AMIME::Address)).dup
    end

    [] of AMIME::Address
  end

  # Sets the cc addresses of this email to the provided *addresses*, overriding any previously added ones.
  def bcc(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "bcc", addresses
  end

  # Appends the provided *addresses* to the list of current bcc addresses.
  def add_bcc(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "bcc", addresses
  end

  private def add_list_address_header_body(name : String, addresses : Enumerable(AMIME::Address | String)) : self
    unless header = @headers[name, AMIME::Header::MailboxList]?
      return self.set_list_address_header_body name, addresses
    end

    header.add_addresses AMIME::Address.create_multiple addresses

    self
  end

  private def set_list_address_header_body(name : String, addresses : Enumerable(AMIME::Address | String)) : self
    addresses = AMIME::Address.create_multiple addresses

    if header = @headers[name]?
      header.body = addresses
    else
      @headers.add_mailbox_list_header name, addresses
    end

    self
  end

  # Returns the priority of this email.
  def priority : AMIME::Email::Priority
    priority = (@headers.header_body("x-priority") || "").as String

    if !(val = priority.to_i?(strict: false)) || !(member = Priority.from_value? val)
      return Priority::NORMAL
    end

    member
  end

  # Sets the priority of this email to the provided *priority*.
  def priority(priority : AMIME::Email::Priority) : self
    @headers.upsert "x-priority", priority.to_s, ->@headers.add_text_header(String, String)

    self
  end

  # Sets the textual content of this email to the provided *body*, optionally with the provided *charset*.
  def text(body : String | IO | Nil, charset : String = "UTF-8") : self
    @cached_body = nil
    @text = body
    @text_charset = charset

    self
  end

  # Returns the textual content of this email.
  def text_body : IO | String | Nil
    @text
  end

  # Sets the HTML content of this email to the provided *body*, optionally with the provided *charset*.
  def html(body : String | IO | Nil, charset : String = "UTF-8") : self
    @cached_body = nil
    @html = body
    @html_charset = charset

    self
  end

  # Returns the HTML content of this email.
  def html_body : IO | String | Nil
    @html
  end

  # Adds an attachment with the provided *body*, optionally with the provided *name* and *content_type*.
  def attach(body : String | IO, name : String? = nil, content_type : String? = nil) : self
    self.add_part AMIME::Part::Data.new body, name, content_type
  end

  # Attaches the file at the provided *path* as an attachment, optionally with the provided *name* and *content_type*.
  def attach_from_path(path : String | Path, name : String? = nil, content_type : String? = nil) : self
    self.add_part AMIME::Part::Data.new AMIME::Part::File.new(path), name, content_type
  end

  # Adds an embedded attachment with the provided *body*, optionally with the provided *name* and *content_type*.
  def embed(body : String | IO, name : String? = nil, content_type : String? = nil) : self
    self.add_part AMIME::Part::Data.new(body, name, content_type).as_inline
  end

  # Embeds the file at the provided *path* as an attachment, optionally with the provided *name* and *content_type*.
  def embed_from_path(path : String | Path, name : String? = nil, content_type : String? = nil) : self
    self.add_part AMIME::Part::Data.new(AMIME::Part::File.new(path), name, content_type).as_inline
  end

  # Adds the provided *part* as an email attachment.
  # Consider using `#attach` or `#embed` or one of their variants to provide a simpler API.
  def add_part(part : AMIME::Part::Data) : self
    @cached_body = nil
    @attachments << part

    self
  end

  # Returns the MIME representation of this email.
  def body : AMIME::Part::Abstract
    if body = super
      return body
    end

    self.generate_body
  end

  # Used in specs
  protected def generate_body : AMIME::Part::Abstract
    if cached_body = @cached_body
      return cached_body
    end

    self.ensure_body_is_valid

    html_part, other_parts, related_parts = self.prepare_parts

    part = (text = @text) ? AMIME::Part::Text.new(text, @text_charset) : nil

    if html_part
      part = part ? AMIME::Part::Multipart::Alternative.new(part, html_part) : html_part
    end

    unless related_parts.empty?
      part = AMIME::Part::Multipart::Related.new part.not_nil!, related_parts
    end

    unless other_parts.empty?
      part = if part
               AMIME::Part::Multipart::Mixed.new other_parts.unshift(part)
             else
               AMIME::Part::Multipart::Mixed.new other_parts
             end
    end

    @cached_body = part.not_nil!
  end

  # ameba:disable Metrics/CyclomaticComplexity:
  private def prepare_parts : {AMIME::Part::Text?, Array(AMIME::Part::Abstract), Array(AMIME::Part::Abstract)}
    names = [] of String
    html_part = nil
    if html = @html
      html_part = AMIME::Part::Text.new html, @html_charset, "html"
      html = html_part.body

      regexes = {
        /<img\s+[^>]*src\s*=\s*(?:([\'"])cid:(.+?)\1|cid:([^>\s]+))/i,
        /<\w+\s+[^>]*background\s*=\s*(?:([\'"])cid:(.+?)\1|cid:([^>\s]+))/i,
      }

      regexes.each do |regex|
        html.scan regex do |matches|
          if m2 = matches[2]?
            names << m2
          end

          if m3 = matches[3]?
            names << m3
          end
        end
      end

      names = names.uniq!
    end

    other_parts = Array(AMIME::Part::Abstract).new
    related_parts = Hash(String, AMIME::Part::Abstract).new

    @attachments.each do |part|
      skip_part = names.each do |name|
        if name != part.name && (!part.has_content_id? || name != part.content_id)
          next
        end

        break true if related_parts.has_key? name

        if html && name != part.content_id
          html = html.gsub("cid:#{name}", "cid:#{part.content_id}")
        end
        related_parts[name] = part
        part.name = part.content_id
        part.as_inline

        break true
      end

      next if skip_part

      other_parts << part
    end

    if html_part
      html_part = AMIME::Part::Text.new html.not_nil!, @html_charset.not_nil!, "html"
    end

    {html_part, other_parts, related_parts.values}
  end

  # :inherit:
  def ensure_validity! : Nil
    self.ensure_body_is_valid

    if "1" == @headers.header_body("x-unsent")
      raise AMIME::Exception::Logic.new "Cannot send messages marked as 'draft'."
    end

    super
  end

  private def ensure_body_is_valid : Nil
    if @text.nil? && @html.nil? && @attachments.empty?
      raise AMIME::Exception::Logic.new "A message must have a text or an HTML part or attachments."
    end
  end
end
