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

  private HEADER_CLASS_MAP = {
    "date" => AMIME::Header::Date,
  } of String => AMIME::Header::Abstract.class | Array(AMIME::Header::Abstract.class)

  # :nodoc:
  enum Type
    TEXT
    DATE
  end

  def self.check_header_class(header : AMIME::Header::Interface) : Nil
    is_valid, header_clases = case header.name.downcase
                              when "date"        then {header.is_a?(AMIME::Header::Date), {AMIME::Header::Date}}
                              when "from"        then {header.is_a?(AMIME::Header::MailboxList), {AMIME::Header::MailboxList}}
                              when "sender"      then {header.is_a?(AMIME::Header::Mailbox), {AMIME::Header::Mailbox}}
                              when "reply-to"    then {header.is_a?(AMIME::Header::MailboxList), {AMIME::Header::MailboxList}}
                              when "to"          then {header.is_a?(AMIME::Header::MailboxList), {AMIME::Header::MailboxList}}
                              when "cc"          then {header.is_a?(AMIME::Header::MailboxList), {AMIME::Header::MailboxList}}
                              when "bcc"         then {header.is_a?(AMIME::Header::MailboxList), {AMIME::Header::MailboxList}}
                              when "message-id"  then {header.is_a?(AMIME::Header::Identification), {AMIME::Header::Identification}}
                              when "return-path" then {header.is_a?(AMIME::Header::Path), {AMIME::Header::MailboxList}}
                                # `in-reply-to` and `references` are less strict than RFC 2822 (3.6.4) to allow users entering the original email's `message-id`, even if that is no valid `message-id`
                              when "in-reply-to" then {header.is_a?(AMIME::Header::Unstructured) || header.is_a?(AMIME::Header::Identification), {AMIME::Header::Unstructured, AMIME::Header::Identification}}
                              when "references"  then {header.is_a?(AMIME::Header::Unstructured) || header.is_a?(AMIME::Header::Identification), {AMIME::Header::Unstructured, AMIME::Header::Identification}}
                              else
                                {true, [] of NoReturn}
                              end

    return if is_valid

    raise AMIME::Exception::Logic.new "The '#{header.name}' header must be an instance of '#{header_clases.join("' or '")}' (got '#{header.class}')."
  end

  def self.is_unique_header?(name : String) : Bool
    UNIQUE_HEADERS.includes? name.downcase
  end

  getter line_length : Int32 = 76

  @headers = Hash(String, Array(AMIME::Header::Interface)).new { |hash, key| hash[key] = Array(AMIME::Header::Interface).new }

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

  def line_length=(@line_length : Int32) : Nil
    self.all do |header|
      header.max_line_length = @line_length
    end
  end

  def to_s(io : IO) : Nil
    self.all do |header|
      header.to_s(io)
      io << '\r' << '\n'
    end
  end

  def to_a : Array(String)
    headers = [] of String

    self.all do |header|
      headers << header.to_s unless header.body_to_s.blank?
    end

    headers
  end

  def all : Array(AMIME::Header::Interface)
    @headers.each_value.flat_map do |headers|
      headers
    end.to_a
  end

  def all(& : AMIME::Header::Interface ->) : Nil
    @headers.each_value do |headers|
      headers.each do |header|
        yield header
      end
    end
  end

  def all(name : String, & : AMIME::Header::Interface ->) : Nil
    @headers[name.downcase]?.try &.each do |header|
      yield header
    end
  end

  def names : Array(String)
    @headers.keys
  end

  def delete(name : String) : Nil
    @headers.delete name
  end

  def [](name : String) : AMIME::Header::Interface
    name = name.downcase

    if !(header_list = @headers[name]?) || !(first_header = header_list.first?)
      raise AMIME::Exception::HeaderNotFound.new "No headers with the name '#{name}' exist."
    end

    first_header
  end

  def [](name : String, _type : T.class) : T forall T
    self.[name].as T
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
    self.class.check_header_class header

    header.max_line_length = @line_length
    name = header.name.downcase

    if UNIQUE_HEADERS.includes?(name) && (header_list = @headers[name]?) && header_list.size > 0
      raise AMIME::Exception::Logic.new "Cannot set header '#{name}' as it is already defined and must be unique."
    end

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

  def add_id_header(name : String, body : String | Array(String)) : self
    self << AMIME::Header::Identification.new name, body
  end

  def add_text_header(name : String, body : String) : self
    self << AMIME::Header::Unstructured.new name, body
  end

  def add_date_header(name : String, body : Time) : self
    self << AMIME::Header::Date.new name, body
  end

  def add_path_header(name : String, body : AMIME::Address | String) : self
    self << AMIME::Header::Path.new name, AMIME::Address.create(body)
  end

  def add_mailbox_header(name : String, body : AMIME::Address | String) : self
    self << AMIME::Header::Mailbox.new name, AMIME::Address.create(body)
  end

  def add_mailbox_list_header(name : String, body : Enumerable(AMIME::Address | String)) : self
    self << AMIME::Header::MailboxList.new name, AMIME::Address.create_multiple(body)
  end

  def add_parameterized_header(name : String, body : String, params : Hash(String, String) = {} of String => String) : self
    self << AMIME::Header::Parameterized.new name, body, params
  end

  def header_parameter(name : String, parameter : String) : String?
    header = self.[name]

    unless header.is_a? Parameterized
      raise AMIME::Exception::Logic.new "Unable to get parameter '#{parameter}' on header '#{name}' as the header is not of class '#{AMIME::Header::Parameterized}'."
    end

    header[parameter]
  end

  protected def header_parameter(name : String, parameter : String, value : String?) : Nil
    header = self.[name]

    unless header.is_a? Parameterized
      raise AMIME::Exception::Logic.new "Unable to set parameter '#{parameter}' on header '#{name}' as the header is not of class '#{AMIME::Header::Parameterized}'."
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
