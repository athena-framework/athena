class Athena::MIME::Header::Date < Athena::MIME::Header::Abstract(Time)
  @value : Time

  def initialize(name : String, @value : Time)
    super name
  end

  def body : Time
    @value
  end

  def body=(body : Time)
    @value = body
  end

  def body_to_s(io : IO) : Nil
    @value.to_rfc2822 io
  end
end
