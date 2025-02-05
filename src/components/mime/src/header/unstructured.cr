# Represents a simple MIME Header (key/value).
class Athena::MIME::Header::Unstructured < Athena::MIME::Header::Abstract(String)
  @value : String

  def initialize(name : String, @value : String)
    super name
  end

  # :inherit:
  def body : String
    @value
  end

  # :inherit:
  def body=(body : String)
    @value = body
  end

  protected def body_to_s(io : IO) : Nil
    io << self.encode_words self, @value
  end
end
