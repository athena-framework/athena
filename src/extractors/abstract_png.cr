require "./extractor"

abstract struct Athena::ImageSize::Extractors::AbstractPNG < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, read_only: true]

  # Based on https://github.com/php/php-src/blob/95da6e807a948039d3a42defbd849c4fed6cbe35/ext/standard/image.c#L299.
  def self.extract(io : IO) : AIS::Image?
    io.skip 4 # Skip data length and type

    return if "IHDR" != io.read_string(4)

    width = io.read_bytes UInt32, IO::ByteFormat::BigEndian
    height = io.read_bytes UInt32, IO::ByteFormat::BigEndian
    bits = io.read_bytes UInt8, IO::ByteFormat::BigEndian

    io.skip 8 # Skip rest of chunk data, and CRC

    format = Image::Format::PNG

    # Determine if the PNG is an actual PNG or an APNG
    loop do
      data_chunk_length = io.read_bytes UInt32, IO::ByteFormat::BigEndian
      chunk_type = io.read_string 4

      break if chunk_type.in? "IDAT", "IEND", nil
      if "acTL" == chunk_type
        format = Image::Format::APNG
        break
      end

      io.skip data_chunk_length + 4 # Skips data and CRC chunk
    end

    Image.new width, height, format, bits
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    return false unless bytes[0, 3] == SIGNATURE[0, 3]

    eight_bytes = Bytes.new 8
    io.pos -= 3
    io.read_fully eight_bytes

    eight_bytes == SIGNATURE
  end
end
