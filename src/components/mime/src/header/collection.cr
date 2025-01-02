class Athena::MIME::Header::Collection
  private UNIQUE_HEADERS = [
    "bcc",
    "cc",
    "date",
    "from",
    "in-reply-to",
    "message-id",
    "references",
    "reply-to",
    "sender",
    "subject",
    "to",
  ]

  # :nodoc:
  enum Type
    TEXT
    DATE
  end

  getter headers = Hash(String, Array(AMIME::Header::Interface)).new { |hash, key| hash[key] = Array(AMIME::Header::Interface).new }
  @line_length = 76

  def self.new(*headers : AMIME::Header::Interface)
    new headers
  end

  def initialize(headers : Enumerable(AMIME::Header::Interface) = [] of AMIME::Header::Interface)
    headers.each do |h|
      self << h
    end
  end

  def_clone

  def_equals @headers, @line_length

  def to_s(io : IO) : Nil
    @headers.each do |_, collection|
      collection.each do |header|
        header.to_s(io)
        io << '\r' << '\n'
      end
    end
  end

  def delete(name : String) : Nil
    @headers.delete name
  end

  def [](name : String) : AMIME::Header::Interface
    @headers[name].first
  end

  def [](name : String, _type : T.class) : T forall T
    @headers[name].first.as T
  end

  def []?(name : String, _type : T.class) : T? forall T
    return unless header = self.[name]?

    header.as T
  end

  def []?(name : String) : AMIME::Header::Interface?
    name = name.downcase

    return unless headers = @headers[name]?

    headers.first?
  end

  def <<(header : AMIME::Header::Interface) : self
    # Check header class
    header.max_line_length = @line_length
    name = header.name.downcase

    # Check for unique headers

    @headers[name] << header

    self
  end

  def header_body(name : String)
    return unless header = self.[name]?

    header.body
  end

  def has_key?(name : String) : Bool
    @headers.has_key? name.downcase
  end

  def add_id_header(name : String, body : String | Array(String)) : Nil
    self << AMIME::Header::Identification.new name, body
  end

  def add_text_header(name : String, body : String) : Nil
    self << AMIME::Header::Unstructured.new name, body
  end

  def add_date_header(name : String, body : Time) : Nil
    self << AMIME::Header::Date.new name, body
  end

  def add_path_header(name : String, body : AMIME::Address | String) : Nil
    self << AMIME::Header::Path.new name, AMIME::Address.create(body)
  end

  def add_mailbox_header(name : String, body : AMIME::Address | String) : Nil
    self << AMIME::Header::Mailbox.new name, AMIME::Address.create(body)
  end

  def add_mailbox_list_header(name : String, body : Array(AMIME::Address | String)) : Nil
    self << AMIME::Header::MailboxList.new name, AMIME::Address.create_multiple(body)
  end

  def add_parameterized_header(name : String, body : String, params : Hash(String, String) = {} of String => String) : Nil
    self << AMIME::Header::Parameterized.new name, body, params
  end

  protected def header_parameter(name : String, parameter : String, value : String?) : Nil
    unless header = self.[name]?
      raise "BUG: Missing header"
    end

    unless header.is_a? Parameterized
      raise "BUG: Not parameterizable"
    end

    header[parameter] = value
  end

  protected def upsert(name : String, body : T, adder : Proc(String, T, Nil)) : Nil forall T
    if header = self[name]?
      return header.body = body
    end

    adder.call name, body
  end
end
