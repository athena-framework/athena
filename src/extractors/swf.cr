struct Athena::ImageSize::Extractors::SWF < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes['F'.ord, 'W'.ord, 'S'.ord, read_only: true]

  def self.extract(io : IO) : AIS::Image?
    io.skip 5

    buffer = Bytes.new 32
    io.read_fully buffer
    bits = self.get_bits buffer, 0, 5

    width = (self.get_bits(buffer, 5 + 15, 15) - self.get_bits(buffer, 5, bits)) // 20
    height = (self.get_bits(buffer, 5 + (3 * bits), bits) - self.get_bits(buffer, 5 + (2 * bits), bits)) // 20

    Image.new width, height, :swf
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 3] == SIGNATURE
  end

  private def self.get_bits(buffer : Bytes, pos : Int32, count : Int32) : Int32
    result = 0
    l = pos

    while l < (pos + count)
      result += ((((buffer[l // 8].to_i) >> (7 - (l % 8))) & 0x01) << (count - (l - pos) - 1))

      l += 1
    end

    result
  end
end
