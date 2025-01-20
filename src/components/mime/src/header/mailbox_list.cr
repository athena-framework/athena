# Represents a Mailbox MIME Header for something like `from`, `to`, `cc`, or `bcc` (one or more named address).
class Athena::MIME::Header::MailboxList < Athena::MIME::Header::Abstract(Array(Athena::MIME::Address))
  @value : Array(AMIME::Address)

  def initialize(name : String, @value : Array(AMIME::Address))
    super name
  end

  # :inherit:
  def body : Array(AMIME::Address)
    @value
  end

  # :inherit:
  def body=(body : Array(AMIME::Address))
    @value = body
  end

  # Adds the provided *addresses* to use in the value of this header.
  def add_addresses(addresses : Array(AMIME::Address)) : Nil
    @value.concat addresses
  end

  # Returns the full mailbox list of this Header as an array of valid RFC 2822 strings.
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

  protected def body_to_s(io : IO) : Nil
    self.address_strings.join io, ", "
  end

  private def token_needs_encoding?(token : String) : Bool
    token.matches?(/[()<>\[\]:;@\,."]/, options: :no_utf_check) || super
  end
end
