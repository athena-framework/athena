struct Athena::ImageSize::Extractors::MNG < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes[0x8a, 0x4d, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, read_only: true]

  def self.extract(io : IO) : AIS::Image?
    io.skip 4 # Skip the version string

    return if "MHDR" != io.read_string(4)

    width = io.read_bytes UInt32, IO::ByteFormat::BigEndian
    height = io.read_bytes UInt32, IO::ByteFormat::BigEndian

    Image.new width, height, :mng
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 8] == SIGNATURE
  end
end
