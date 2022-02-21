struct Athena::ImageSize::Extractors::MMTIFF < Athena::ImageSize::Extractors::AbstractTIFF
  private SIGNATURE = Bytes['M'.ord, 'M'.ord, 0x00, 0x2A, read_only: true]

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 4] == SIGNATURE
  end

  protected def self.byte_format : IO::ByteFormat
    IO::ByteFormat::BigEndian
  end
end
