# Represents a collection of MIME headers.
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

  # Checks the provided *header* to ensure its name and type are compatible.
  #
  # ```
  # AMIME::Header::Collection.check_header_class AMIME::Header::Date.new("date", Time.utc) # => nil
  # AMIME::Header::Collection.check_header_class AMIME::Header::Unstructured.new("date", "blah")
  # # => AMIME::Exception::Logic: The 'date' header must be an instance of 'Athena::MIME::Header::Date' (got 'Athena::MIME::Header::Unstructured').
  # ```
  #
  # ameba:disable Metrics/CyclomaticComplexity:
  def self.check_header_class(header : AMIME::Header::Interface) : Nil
    is_valid, header_classes = case header.name.downcase
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

    raise AMIME::Exception::Logic.new "The '#{header.name}' header must be an instance of '#{header_classes.join("' or '")}' (got '#{header.class}')."
  end

  # Returns `true` if the provided *header* name is required to be unique.
  def self.unique_header?(name : String) : Bool
    UNIQUE_HEADERS.includes? name.downcase
  end

  # Returns the
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

  # Sets the max line length to use for this collection.
  def line_length=(@line_length : Int32) : Nil
    self.all do |header|
      header.max_line_length = @line_length
    end
  end

  # :nodoc:
  def to_s(io : IO) : Nil
    self.all do |header|
      header.to_s(io)
      io << '\r' << '\n'
    end
  end

  # Returns the string representation of each header in the collection as an array of strings.
  def to_a : Array(String)
    headers = [] of String

    self.all do |header|
      headers << header.to_s unless header.body_to_s.blank?
    end

    headers
  end

  # Returns an array of all `AMIME::Header::Interface` instances stored within the collection.
  def all : Array(AMIME::Header::Interface)
    @headers.each_value.flat_map do |headers|
      headers
    end.to_a
  end

  # Yields each `AMIME::Header::Interface` instance stored within the collection.
  def all(& : AMIME::Header::Interface ->) : Nil
    @headers.each_value do |headers|
      headers.each do |header|
        yield header
      end
    end
  end

  # Yields each `AMIME::Header::Interface` instance stored within the collection with the provided *name*.
  def all(name : String, & : AMIME::Header::Interface ->) : Nil
    @headers[name.downcase]?.try &.each do |header|
      yield header
    end
  end

  # Returns the names of all headers stored within the collection as an array of strings.
  def names : Array(String)
    @headers.keys
  end

  # Removes the header(s) with the provided *name* from the collection.
  def delete(name : String) : Nil
    @headers.delete name
  end

  # Returns the first header with the provided *name*.
  # Raises an `AMIME::Exception::HeaderNotFound` exception if no header with that name exists.
  def [](name : String) : AMIME::Header::Interface
    name = name.downcase

    if !(header_list = @headers[name]?) || !(first_header = header_list.first?)
      raise AMIME::Exception::HeaderNotFound.new "No headers with the name '#{name}' exist."
    end

    first_header
  end

  # Returns the first header with the provided *name* casted to type `T`.
  # Raises an `AMIME::Exception::HeaderNotFound` exception if no header with that name exists.
  def [](name : String, _type : T.class) : T forall T
    self.[name].as T
  end

  # Returns the first header with the provided *name* casted to type `T`, or `nil` if no headers with that name exist.
  def []?(name : String, _type : T.class) : T? forall T
    return unless header = self.[name]?

    header.as T
  end

  # Returns the first header with the provided *name*, or `nil` if no headers with that name exist.
  def []?(name : String) : AMIME::Header::Interface?
    name = name.downcase

    return unless headers = @headers[name]?

    headers.first?
  end

  # Adds the provided *header* to the collection.
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

  # Returns the body of the first header with the provided *name*.
  def header_body(name : String)
    return unless header = self.[name]?

    header.body
  end

  # Returns `true` if the collection contains a header with the provided *name*, otherwise `false`.
  def has_key?(name : String) : Bool
    @headers.has_key? name.downcase
  end

  # Adds an `AMIME::Header::Identification` header to the collection with the provided *name* and *body*.
  def add_id_header(name : String, body : String | Array(String)) : self
    self << AMIME::Header::Identification.new name, body
  end

  # Adds an `AMIME::Header::Unstructured` header to the collection with the provided *name* and *body*.
  def add_text_header(name : String, body : String) : self
    self << AMIME::Header::Unstructured.new name, body
  end

  # Adds an `AMIME::Header::Date` header to the collection with the provided *name* and *body*.
  def add_date_header(name : String, body : Time) : self
    self << AMIME::Header::Date.new name, body
  end

  # Adds an `AMIME::Header::Path` header to the collection with the provided *name* and *body*.
  def add_path_header(name : String, body : AMIME::Address | String) : self
    self << AMIME::Header::Path.new name, AMIME::Address.create(body)
  end

  # Adds an `AMIME::Header::Mailbox` header to the collection with the provided *name* and *body*.
  def add_mailbox_header(name : String, body : AMIME::Address | String) : self
    self << AMIME::Header::Mailbox.new name, AMIME::Address.create(body)
  end

  # Adds an `AMIME::Header::MailboxList` header to the collection with the provided *name* and *body*.
  def add_mailbox_list_header(name : String, body : Enumerable(AMIME::Address | String)) : self
    self << AMIME::Header::MailboxList.new name, AMIME::Address.create_multiple(body)
  end

  # Adds an `AMIME::Header::Parameterized` header to the collection with the provided *name* and *body*.
  def add_parameterized_header(name : String, body : String, params : Hash(String, String) = {} of String => String) : self
    self << AMIME::Header::Parameterized.new name, body, params
  end

  # Returns the value of the provided *parameter* for the first `AMIME::Header::Parameterized` header with the provided *name*.
  #
  # ```
  # headers = AMIME::Header::Collection.new
  # headers.add_parameterized_header "content-type", "text/plain", {"charset" => "UTF-8"}
  # headers.header_parameter "content-type", "charset" # => "UTF-8"
  # ```
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
