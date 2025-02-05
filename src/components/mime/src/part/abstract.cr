# Base type of all parts that provides common utilities and abstractions.
abstract class Athena::MIME::Part::Abstract
  # Returns the headers associated with this part.
  getter headers : AMIME::Header::Collection = AMIME::Header::Collection.new

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

  protected abstract def body_to_s(io : IO) : Nil

  # Returns the media type of this part.
  # E.g. `application` within `application/pdf`.
  abstract def media_type : String

  # Returns the media sub-type of this part.
  # E.g. `pdf` within `application/pdf`.
  abstract def media_sub_type : String

  # Returns a cloned `AMIME::Header::Collection` consisting of a final representation of the headers associated with this message.
  # I.e. Ensures the message's headers include the required ones.
  def prepared_headers : AMIME::Header::Collection
    headers = @headers.clone

    headers.upsert "content-type", "#{self.media_type}/#{self.media_sub_type}", ->headers.add_parameterized_header(String, String)

    headers
  end

  # Returns a string representation of the body of this part, excluding any headers.
  def body_to_s : String
    String.build do |io|
      self.body_to_s io
    end
  end

  # def inspect(io : IO) : Nil
  #   self.media_type.to_s io
  #   io << '/'
  #   self.media_sub_type.to_s io
  # end

  # :nodoc:
  def to_s(io : IO) : Nil
    self.prepared_headers.to_s io
    io << '\r' << '\n'
    self.body_to_s io
  end
end
