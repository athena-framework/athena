class Athena::MIME::Header::Identification < Athena::MIME::Header::Abstract(Array(String))
  getter ids : Array(String) = [] of String
  getter ids_as_addresses : Array(AMIME::Address) = [] of AMIME::Address

  def initialize(name : String, value : String | Array(String))
    super name

    self.id = value
  end

  def body : Array(String)
    @ids
  end

  def body=(body : String | Array(String))
    self.id = body
  end

  def id : String?
    @ids.first?
  end

  def id=(id : String | Array(String)) : Nil
    self.ids = id.is_a?(String) ? [id] : id
  end

  def ids=(ids : Array(String)) : Nil
    @ids.clear
    @ids_as_addresses.clear

    ids.each do |id|
      @ids << id
      @ids_as_addresses << AMIME::Address.new id
    end
  end

  def body_to_s(io : IO) : Nil
    @ids_as_addresses.join io, ' ' do |address, io|
      io << '<'
      address.to_s io
      io << '>'
    end
  end
end
