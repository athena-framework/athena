# Represents a `date` MIME Header.
class Athena::MIME::Header::Date < Athena::MIME::Header::Abstract(Time)
  @value : Time

  def initialize(name : String, @value : Time)
    super name
  end

  # :inherit:
  def body : Time
    @value
  end

  # :inherit:
  def body=(body : Time)
    @value = body
  end

  protected def body_to_s(io : IO) : Nil
    @value.to_rfc2822 io
  end
end
