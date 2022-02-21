struct Athena::ImageSize::Extractors::PSD < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes['8'.ord, 'B'.ord, 'P'.ord, 'S'.ord, read_only: true]

  def self.extract(io : IO) : AIS::Image?
    io.skip 8 # Skip version and reversed section

    channels = io.read_bytes UInt16, IO::ByteFormat::BigEndian
    height = io.read_bytes UInt32, IO::ByteFormat::BigEndian
    width = io.read_bytes UInt32, IO::ByteFormat::BigEndian
    bits = io.read_bytes UInt16, IO::ByteFormat::BigEndian

    Image.new width, height, :psd, bits, channels
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 4] == SIGNATURE
  end
end
