require "./interface"

abstract class Athena::MIME::Header::Abstract(T)
  include Interface

  private PHRASE_REGEX = Regex.new(%q(^(?:(?:(?:(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?[a-zA-Z0-9!#\$%&\'\*\+\-\/=\?\^_`\{\}\|~]+(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?)|(?:(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?"((?:(?:[ \t]*(?:\r\n))?[ \t])?(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21\x23-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])))*(?:(?:[ \t]*(?:\r\n))?[ \t])?"(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))*(?:(?:(?:(?:[ \t]*(?:\r\n))?[ \t])?(\((?:(?:(?:[ \t]*(?:\r\n))?[ \t])|(?:(?:[\x01-\x08\x0B\x0C\x0E-\x19\x7F]|[\x21-\x27\x2A-\x5B\x5D-\x7E])|(?:\\[\x00-\x08\x0B\x0C\x0E-\x7F])|(?1)))*(?:(?:[ \t]*(?:\r\n))?[ \t])?\)))|(?:(?:[ \t]*(?:\r\n))?[ \t])))?))+?)$), options: :dollar_endonly)

  protected class_getter encoder : AMIME::Encoder::QuotedPrintableMIMEHeader do
    AMIME::Encoder::QuotedPrintableMIMEHeader.new
  end

  getter name : String
  property max_line_length : Int32 = 76
  property lang : String? = nil
  property charset : String = "UTF-8"

  def initialize(@name : String); end

  abstract def body : T
  abstract def body=(body : T)

  def_clone

  macro inherited
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

  def to_s(io : IO) : Nil
    # TODO: Is there a way to make this more stream based?
    io << self.tokens_to_string self.to_tokens
  end

  private def generate_token_lines(token : String) : Array(String)
    token.split /(\r\n)/, options: :no_utf_check
  end

  private def tokens_to_string(tokens : Array(String)) : String
    line_count = 0
    header_lines = ["#{@name}: "]

    current_line = header_lines[line_count]

    tokens.each_with_index do |token, i|
      if (token == "\r\n") || (i > 0 && (current_line + token).size > @max_line_length) && current_line != ""
        header_lines << ""
        header_lines[line_count] = current_line
        line_count += 1
        current_line = header_lines[line_count]
      end

      unless token == "\r\n"
        header_lines[line_count] += token
      end
    end

    header_lines.join("\r\n")
  end

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

  private def create_phrase(header : AMIME::Header::Interface, input : String, charset : String, shorten : Bool = false) : String
    phrase_str = input

    if !phrase_str.matches? PHRASE_REGEX
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
