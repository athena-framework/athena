struct Athena::MIME::Address
  private FROM_STRING_PATTERN = /(?<displayName>[^<]*)<(?<addrSpec>.*)>[^>]*/

  protected class_getter encoder : AMIME::Encoder::AddressEncoderInterface do
    AMIME::Encoder::IDNAddress.new
  end

  getter address : String
  getter name : String

  def self.create_multiple(*addresses : self | String) : Array(self)
    self.create_multiple addresses
  end

  def self.create_multiple(addresses : Enumerable(self | String)) : Array(self)
    addresses.map do |a|
      self.create a
    end.to_a
  end

  def self.create(address : self | String) : self
    return address if address.is_a? self

    return new(address) unless address.includes? '<'

    unless match = address.match FROM_STRING_PATTERN
      raise AMIME::Exception::InvalidArgument.new "Could not parse '#{address}' to a '#{self}' instance."
    end

    new match["addrSpec"], match["displayName"].strip(" '\"")
  end

  def initialize(address : String, name : String = "")
    @address = address.strip
    @name = name.gsub(/\n|\r/, "").strip

    # TODO: Validate the email
  end

  def_clone

  def to_s(io : IO) : Nil
    if name = self.encoded_name.presence
      return io << %("#{name}" <#{self.encoded_address}>)
    end

    io << self.encoded_address
  end

  def encoded_address : String
    self.class.encoder.encode @address
  end

  def encoded_name : String
    @name
  end

  def has_unicode_local_part? : Bool
    local, _, _ = @address.partition '@'

    !local.ascii_only?
  end
end
