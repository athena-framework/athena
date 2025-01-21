# Represents an ID MIME Header for something like `message-id` or `content-id` (one or more addresses).
class Athena::MIME::Header::Identification < Athena::MIME::Header::Abstract(Array(String))
  getter ids : Array(String) = [] of String
  getter ids_as_addresses : Array(AMIME::Address) = [] of AMIME::Address

  def initialize(name : String, value : String | Array(String))
    super name

    self.id = value
  end

  # :inherit:
  def body : Array(String)
    @ids
  end

  # :inherit:
  def body=(body : String | Array(String))
    self.id = body
  end

  # Returns the ID used in the value of this header.
  # If multiple IDs are set, only the first is returned.
  def id : String?
    @ids.first?
  end

  # Sets the ID used in the value of this header.
  def id=(id : String | Array(String)) : Nil
    self.ids = id.is_a?(String) ? [id] : id
  end

  # Sets a collection of IDs to use in the value of this header.
  def ids=(ids : Array(String)) : Nil
    @ids.clear
    @ids_as_addresses.clear

    ids.each do |id|
      @ids << id
      @ids_as_addresses << AMIME::Address.new id
    end
  end

  protected def body_to_s(io : IO) : Nil
    @ids_as_addresses.join io, ' ' do |address, i|
      i << '<'
      address.to_s i
      i << '>'
    end
  end
end
