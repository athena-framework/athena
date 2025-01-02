class Athena::MIME::Header::Path < Athena::MIME::Header::Abstract(Athena::MIME::Address)
  @value : AMIME::Address

  def initialize(name : String, @value : AMIME::Address)
    super name
  end

  def body : AMIME::Address
    @value
  end

  def body=(body : AMIME::Address)
    @value = body
  end

  def body_to_s(io : IO) : Nil
    io << '<'
    @value.to_s io
    io << '>'
  end
end
