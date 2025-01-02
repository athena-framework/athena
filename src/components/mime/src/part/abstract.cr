abstract class Athena::MIME::Part::Abstract
  getter headers : AMIME::Header::Collection = AMIME::Header::Collection.new

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

  abstract def body_to_s(io : IO) : Nil

  abstract def media_type : String
  abstract def media_sub_type : String

  def prepared_headers : AMIME::Header::Collection
    headers = @headers.clone

    headers.upsert "content-type", "#{self.media_type}/#{self.media_sub_type}", ->headers.add_parameterized_header(String, String)

    headers
  end

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

  def to_s(io : IO) : Nil
    self.prepared_headers.to_s io
    io << '\r' << '\n'
    self.body_to_s io
  end
end
