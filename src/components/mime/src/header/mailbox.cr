# Represents a Mailbox MIME Header for something like `sender` (one named address).
class Athena::MIME::Header::Mailbox < Athena::MIME::Header::Abstract(Athena::MIME::Address)
  @value : AMIME::Address

  def initialize(name : String, @value : AMIME::Address)
    super name
  end

  # :inherit:
  def body : AMIME::Address
    @value
  end

  # :inherit:
  def body=(body : AMIME::Address)
    @value = body
  end

  protected def body_to_s(io : IO) : Nil
    str = @value.encoded_address

    if name = @value.name.presence
      str = "#{self.create_phrase(self, name, @charset, true)} <#{str}>"
    end

    io << str
  end
end
