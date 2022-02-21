struct Athena::ImageSize::Extractors::IITIFF < Athena::ImageSize::Extractors::AbstractTIFF
  private SIGNATURE = Bytes['I'.ord, 'I'.ord, 0x2A, 0x00, read_only: true]

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 4] == SIGNATURE
  end

  protected def self.byte_format : IO::ByteFormat
    IO::ByteFormat::LittleEndian
  end
end
