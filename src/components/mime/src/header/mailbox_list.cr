class Athena::MIME::Header::MailboxList < Athena::MIME::Header::Abstract(Array(Athena::MIME::Address))
  @value : Array(AMIME::Address)

  def initialize(name : String, @value : Array(AMIME::Address))
    super name
  end

  def body : Array(AMIME::Address)
    @value
  end

  def body=(body : Array(AMIME::Address))
    @value = body
  end

  def add_addresses(addresses : Array(AMIME::Address)) : Nil
    @value.concat addresses
  end

  def address_strings : Array(String)
    first = true

    @value.map do |address|
      str = address.encoded_address

      if name = address.name.presence
        str = "#{self.create_phrase(self, name, @charset, first)} <#{str}>"
      end

      str
    ensure
      first = false
    end
  end

  def body_to_s(io : IO) : Nil
    self.address_strings.join io, ", "
  end

  private def token_needs_encoding?(token : String) : Bool
    token.matches?(/[()<>\[\]:;@\,."]/) || super
  end
end
