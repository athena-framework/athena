require "uri"

# An encoder based on the [RFC2231](https://datatracker.ietf.org/doc/html/rfc2231) spec.
struct Athena::MIME::Encoder::RFC2231
  include Athena::MIME::Encoder::EncoderInterface

  # :nodoc:
  def_clone

  # :inherit:
  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    max_line_length = 75 if !max_line_length || 0 >= max_line_length

    String.build input.size do |io|
      line_length = first_line_offset

      0.step(to: input.size, by: 4, exclusive: true) do |offset|
        encoded_string = URI.encode_path_segment input[offset, 4]

        if (line_length + encoded_string.bytesize) > max_line_length
          io << '\r'
          io << '\n'
          line_length = 0
        end

        io << encoded_string
        line_length += encoded_string.bytesize
      end
    end
  end
end
