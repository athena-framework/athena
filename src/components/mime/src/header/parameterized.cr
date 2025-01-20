require "./unstructured"

# Represents a MIME Header for something like `content-type` (key/value pairs of metadata included in the value).
class Athena::MIME::Header::Parameterized < Athena::MIME::Header::Unstructured
  # RFC 2231's definition of a token.
  private TOKEN_REGEX = Regex.new "^(?:[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+)$", :dollar_endonly

  # Represents the parameters associated with this header.
  property parameters : Hash(String, String) = {} of String => String

  @encoder : AMIME::Encoder::RFC2231? = nil

  def initialize(
    name : String,
    value : String,
    parameters : Hash(String, String) = {} of String => String,
  )
    super name, value

    parameters.each do |k, v|
      self.[k] = v
    end

    if "content-type" != name.downcase
      @encoder = AMIME::Encoder::RFC2231.new
    end
  end

  # Returns the value of the parameter with the provided *name*
  def [](name : String) : String
    @parameters[name]? || ""
  end

  # Set the value of the parameter with the provided *name* to *value*.
  def []=(key : String, value : String) : Nil
    @parameters.merge!({key => value})
  end

  protected def body_to_s(io : IO) : Nil
    super

    @parameters.each do |k, v|
      next unless v.presence

      io << ';' << ' '

      self.write_parameter io, k, v
    end
  end

  # Write an RFC 2047 compliant header parameter from the *name* and *value* to *io*.
  # ameba:disable Metrics/CyclomaticComplexity:
  private def write_parameter(io : IO, name : String, value : String) : Nil
    orig_value = value

    encoded = false

    # Allow room for parameter name, indices, "=", and DQUOTEs
    max_value_length = @max_line_length - "#{name}=*N\"\";".bytesize - 1
    first_line_offset = 0

    # If it's not already a valid parameter
    if !value.matches? TOKEN_REGEX, options: :no_utf_check
      # TODO: Text or something else?
      # ... and it's not ASCII
      unless value.ascii_only?
        encoded = true

        # Allow space for the indices, charset, and language
        max_value_length = @max_line_length - "#{name}*N*=\"\";".bytesize - 1
        first_line_offset = "#{@charset}'#{@lang}'".bytesize
      end

      if name.in?("name", "filename") && "form-data" == @value && "content-disposition" == @name.downcase && !value.ascii_only?
        # WHATWG HTML living standard 4.10.21.8 2 specifies:
        # For field names and filenames for file fields, the result of the
        # encoding in the previous bullet point must be escaped by replacing
        # any 0x0A (LF) bytes with the byte sequence `%0A`, 0x0D (CR) with `%0D`
        # and 0x22 (") with `%22`.
        # The user agent must not perform any other escapes.
        value = value.gsub({'"' => "%22", '\r' => "%0D", '\n' => "%0A"})

        if value.bytesize <= max_line_length
          io << name
          io << '='
          io << '"'
          io << value
          io << '"'
          return
        end

        value = orig_value
      end
    end

    # Encode if needed
    if encoded || value.bytesize > max_value_length
      if encoder = @encoder
        value = encoder.encode orig_value, @charset, first_line_offset, max_value_length
      else
        # TODO: Do we really need to continue to support this non-RFC compliant flow?
        value = self.token_as_encoded_word orig_value
        encoded = false
      end
    end

    value_lines = @encoder ? value.split("\r\n") : [value]

    if value_lines.size > 1
      value_lines.each_with_index.join io, ";\r\n " do |(line, idx), i|
        i << "#{name}*#{idx}"
        self.write_end_of_parameter_value i, line, true, idx.zero?
      end

      return
    end

    io << name

    self.write_end_of_parameter_value io, value_lines[0], encoded, true
  end

  private def write_end_of_parameter_value(io : IO, value : String, encoded : Bool = false, first_line : Bool = false) : Nil
    force_http_quoting = "form-data" == @value && "content-disposition" == @name.downcase

    if force_http_quoting || !value.matches?(TOKEN_REGEX, options: :no_utf_check)
      value = %("#{value}")
    end

    prepend = '='

    if encoded
      prepend = "*="
      if first_line
        prepend = "*=#{@charset}'#{@lang}'"
      end
    end

    io << prepend
    io << value
  end
end
