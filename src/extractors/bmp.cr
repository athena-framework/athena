require "./extractor"

struct Athena::ImageSize::Extractors::BMP < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes['B'.ord, 'M'.ord, read_only: true]

  def self.extract(io : IO) : AIS::Image?
    io.skip 11 # Skip rest of Header chunk

    info_header_length = io.read_bytes UInt32

    if 12 == info_header_length # BITMAPCOREHEADER
      width = io.read_bytes Int16
      height = io.read_bytes Int16

      io.skip 3

      bits = io.read_bytes UInt8
    elsif 40 == info_header_length # BITMAPINFOHEADER
      width = io.read_bytes Int32
      height = io.read_bytes(Int32).abs

      io.skip 2

      bits = io.read_bytes UInt16
    else
      return
    end

    Image.new width, height, :bmp, bits.zero? ? nil : bits
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 2] == SIGNATURE
  end
end
