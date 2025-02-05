# Represents an email address with an optional name.
struct Athena::MIME::Address
  private FROM_STRING_PATTERN = /(?<displayName>[^<]*)<(?<addrSpec>.*)>[^>]*/

  protected class_getter encoder : AMIME::Encoder::AddressEncoderInterface do
    AMIME::Encoder::IDNAddress.new
  end

  # Returns the raw email address portion of this Address.
  # Use `#encoded_address` to get a safe representation for use in a MIME header.
  #
  # ```
  # address = AMIME::Address.new "first.last@example.com", "First Last"
  # address.address # => "first.last@example.com"
  # ```
  getter address : String

  # Returns the raw name portion of this Address, or an empty string if none was set.
  # Use `#encoded_name` to get a safe representation for use in a MIME header.
  #
  # ```
  # address = AMIME::Address.new "first.last@example.com"
  # address.name # => ""
  #
  # address = AMIME::Address.new "first.last@example.com", "First Last"
  # address.name # => "First Last"
  # ```
  getter name : String

  # Creates an array of `AMIME::Address` from the provided *addresses*.
  #
  # ```
  # AMIME::Address.create_multiple "me@example.com", "Mr Smith <smith@example.com>", AMIME::Address.new("you@example.com") # =>
  # # [
  # #   Athena::MIME::Address(@address="me@example.com", @name=""),
  # #   Athena::MIME::Address(@address="smith@example.com", @name="Mr Smith"),
  # #   Athena::MIME::Address(@address="you@example.com", @name=""),
  # # ]
  # ```
  def self.create_multiple(*addresses : self | String) : Array(self)
    self.create_multiple addresses
  end

  # Creates an array of `AMIME::Address` from the provided enumerable *addresses*.
  #
  # ```
  # AMIME::Address.create_multiple({"me@example.com", "Mr Smith <smith@example.com>", AMIME::Address.new("you@example.com")}) # =>
  # # [
  # #   Athena::MIME::Address(@address="me@example.com", @name=""),
  # #   Athena::MIME::Address(@address="smith@example.com", @name="Mr Smith"),
  # #   Athena::MIME::Address(@address="you@example.com", @name=""),
  # # ]
  # ```
  def self.create_multiple(addresses : Enumerable(self | String)) : Array(self)
    addresses.map do |a|
      self.create a
    end.to_a
  end

  # Creates a new `AMIME::Address`.
  #
  # If the *address* is already an `AMIME::Address`, it is returned as is.
  # Otherwise if it's a `String`, then attempt to parse the name and address from the provided string.
  def self.create(address : self | String) : self
    return address if address.is_a? self

    return new(address) unless address.includes? '<'

    unless match = address.match FROM_STRING_PATTERN
      raise AMIME::Exception::InvalidArgument.new "Could not parse '#{address}' to a '#{self}' instance."
    end

    new match["addrSpec"], match["displayName"].strip(" '\"")
  end

  # Creates a new `AMIME::Address` with the provided *address* and optionally *name*.
  def initialize(address : String, name : String = "")
    @address = address.strip
    @name = name.gsub(/\n|\r/, "", options: :no_utf_check).strip

    # TODO: Validate the email
  end

  # :nodoc:
  def_clone

  # Writes an encoded representation of this Address to the provided *io* for use in a MIME header.
  #
  # ```
  # AMIME::Address.new "contact@athenï.org", "George").to_s # => "\"George\" <contact@xn--athen-gta.org>"
  # ```
  def to_s(io : IO) : Nil
    if name = self.encoded_name.presence
      return io << %("#{name}" <#{self.encoded_address}>)
    end

    io << self.encoded_address
  end

  # Returns an encoded representation of `#address` safe to use within a MIME header.
  #
  # ```
  # AMIME::Address.new("contact@athenï.org").encoded_address # => "xn--athen-gta.org"
  # ```
  def encoded_address : String
    self.class.encoder.encode @address
  end

  # Returns an encoded representation of `#name` safe to use within a MIME header.
  #
  # ```
  # AMIME::Address.new("us@example.com", %(Me, "You)).encoded_name # => "Me, \"You"
  # ```
  def encoded_name : String
    @name
  end

  # Returns `true` if this Address's localpart contains at least one non-ASCII character.
  # Otherwise returns `false`.
  #
  # ```
  # AMIME::Address.new("info@dømi.com").has_unicode_local_part? # => false
  # AMIME::Address.new("dømi@dømi.com").has_unicode_local_part? # => true
  # ```
  def has_unicode_local_part? : Bool
    local, _, _ = @address.partition '@'

    !local.ascii_only?
  end
end
