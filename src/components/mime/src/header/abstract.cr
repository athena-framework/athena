require "./interface"

# Base type of all headers that provides common utilities and abstractions.
abstract class Athena::MIME::Header::Abstract(T)
  include Interface

  private PHRASE_REGEX = Regex.new(%q(^(?:(?:(?:(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?[a-zA-Z0-9!#\$%&\'\*\+\-\/=\?\^_`\{\}\|~]+(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?)|(?:(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?"((?:(?:[ \t]*(?:\r\n))?[ \t])?(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21\x23-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])))*(?:(?:[ \t]*(?:\r\n))?[ \t])?"(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?))+?)$), options: :dollar_endonly)

  protected class_getter encoder : AMIME::Encoder::QuotedPrintableMIMEHeader do
    AMIME::Encoder::QuotedPrintableMIMEHeader.new
  end

  # :inherit:
  getter name : String

  # :inherit:
  property max_line_length : Int32 = 76

  # Sets the language used in this header.
  # E.g. `en-us`.
  property lang : String? = nil

  # Sets the character set used in this header.
  # Defaults to `UTF-8`.
  property charset : String = "UTF-8"

  def initialize(@name : String); end

  # Returns the body of this header.
  abstract def body : T

  # Sets the body of this header.
  abstract def body=(body : T)

  # :nodoc:
  def_clone

  macro inherited
    # :nodoc:
    def ==(other : self)
      \{% if @type.class? %}
        return true if same?(other)
      \{% end %}
      \{% for field in @type.instance_vars %}
        return false unless @\{{field.id}} == other.@\{{field.id}}
      \{% end %}
      true
    end
  end

  # :nodoc:
  def to_s(io : IO) : Nil
    # TODO: Is there a way to make this more stream based?
    io << self.tokens_to_string self.to_tokens
  end

  # Generates tokens from the given string which include CRLF as individual tokens.
  private def generate_token_lines(token : String) : Array(String)
    token.split /(\r\n)/, options: :no_utf_check
  end

  # Takes an array of tokens which appear in the header and turns them into an RFC 2822 compliant string, adding FWSP where needed.
  private def tokens_to_string(tokens : Array(String)) : String
    line_pos = 0

    String.build do |io|
      io << @name << ':' << ' '
      line_pos += @name.bytesize + 2

      tokens.each do |token|
        if "\r\n" == token
          line_pos = 0
        elsif (line_pos + token.bytesize) > @max_line_length
          io << "\r\n"
          line_pos = token.bytesize
        else
          line_pos += token.bytesize
        end

        io << token
      end
    end
  end

  # Generate a list of all tokens in the final header.
  private def to_tokens(string : String? = nil) : Array(String)
    string = string || self.body_to_s

    tokens = [] of String
    string.split /(?=[ \t])/, options: :no_utf_check do |token|
      tokens.concat self.generate_token_lines token
    end

    tokens
  end

  private def token_needs_encoding?(token : String) : Bool
    return true unless token.valid_encoding?

    token.each_char.any? do |char|
      ord = char.ord

      0x00 <= ord <= 0x08 ||
        0x10 <= ord <= 0x19 ||
        0x7F <= ord <= 0xFF ||
        char.in?('\r', '\n')
    end
  end

  # Splits a string into tokens in blocks of words which can be encoded quickly.
  private def encodable_word_tokens(string : String) : Array(String)
    tokens = [] of String
    encoded_token = ""

    string.split /(?=[\t ])/, options: :no_utf_check do |token|
      if self.token_needs_encoding? token
        encoded_token += token
      else
        unless encoded_token.empty?
          tokens << encoded_token
          encoded_token = ""
        end
        tokens << token
      end
    end

    unless encoded_token.empty?
      tokens << encoded_token
    end

    tokens
  end

  # Encode needed word tokens within a string of input.
  private def encode_words(header : AMIME::Header::Interface, input : String, used_length : Int32 = -1) : String
    bytes_written = 0

    String.build do |io|
      tokens = self.encodable_word_tokens input

      tokens.each do |token|
        # See RFC 2822, Sect 2.2 (really 2.2 ??)
        if self.token_needs_encoding? token
          # Dont encode starting WSP
          case first_char = token[0]
          when ' ', '\t'
            io << first_char
            bytes_written += first_char.bytesize
            token = token[1..]
          end

          if -1 == used_length
            used_length = "#{header.name}: ".bytesize + bytes_written
          end

          encoded_token = self.token_as_encoded_word token, used_length
          io << encoded_token
          bytes_written += encoded_token.bytesize
        else
          io << token
          bytes_written += token.bytesize
        end
      end
    end
  end

  # Encodes the provided *token* for safe insertion into headers.
  private def token_as_encoded_word(token : String, first_line_offset : Int32 = 0) : String
    # Adjust first_line_offset to account or space needed for syntax
    charset_decl = @charset
    if lang = @lang
      charset_decl = "#{charset_decl}*#{lang}"
    end
    encoded_wrapper_length = "=?#{charset_decl}?#{AMIME::Header::Abstract.encoder.name}??=".bytesize

    if first_line_offset >= 75
      # TODO: Is this needed?
      first_line_offset = 0
    end

    encoded_text_lines = AMIME::Header::Abstract.encoder.encode(token, @charset, first_line_offset, 75 - encoded_wrapper_length).split "\r\n"

    if "iso-2022-jp" != @charset.downcase
      encoded_text_lines.map! do |line|
        "=?#{charset_decl}?#{AMIME::Header::Abstract.encoder.name}?#{line}?="
      end
    end

    encoded_text_lines.join "\r\n "
  end

  # Produces a compliant, formatted RFC 2822 'phrase' based on the provided *input*.
  private def create_phrase(header : AMIME::Header::Interface, input : String, charset : String, shorten : Bool = false) : String
    phrase_str = input

    if !phrase_str.matches? PHRASE_REGEX, options: :no_utf_check
      # If it's just ASCII try escaping some chars and make it a quoted string
      if phrase_str.ascii_only?
        {'\\', '"'}.each do |char|
          phrase_str = phrase_str.gsub char, "\\#{char}"
        end
        phrase_str = %("#{phrase_str}")
      else
        # Otherwise it needs encoded
        used_length = shorten ? "#{header.name}: ".bytesize : 0

        phrase_str = self.encode_words header, input, used_length
      end
    elsif phrase_str.includes? '('
      {'\\', '"'}.each do |char|
        phrase_str = phrase_str.gsub char, "\\#{char}"
      end
      phrase_str = %("#{phrase_str}")
    end

    phrase_str
  end
end
