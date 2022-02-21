struct Athena::ImageSize::Extractors::CUR < Athena::ImageSize::Extractors::AbstractICO
  private SIGNATURE = Bytes[0x00, 0x00, 0x02, 0x00, read_only: true]

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 4] == SIGNATURE
  end

  protected def self.format : AIS::Image::Format
    Image::Format::CUR
  end
end
