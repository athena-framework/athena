struct Athena::ImageSize::Extractors::JPEG < Athena::ImageSize::Extractors::Extractor
  private SIGNATURE = Bytes[0xff, 0xd8, 0xff, read_only: true]

  private enum Block : UInt8
    M_SOF0  = 0xC0 # Start Of Frame N
    M_SOF1  = 0xC1 # N indicates which compression process
    M_SOF2  = 0xC2 # Only SOF0-SOF2 are now in common use
    M_SOF3  = 0xC3
    M_SOF5  = 0xC5 # NB: codes C4 and CC are NOT SOF markers
    M_SOF6  = 0xC6
    M_SOF7  = 0xC7
    M_SOF9  = 0xC9
    M_SOF10 = 0xCA
    M_SOF11 = 0xCB
    M_SOF13 = 0xCD
    M_SOF14 = 0xCE
    M_SOF15 = 0xCF
    M_SOI   = 0xD8
    M_EOI   = 0xD9 # End Of Image (end of datastream)
    M_SOS   = 0xDA # Start Of Scan (begins compressed data)
    M_APP0  = 0xe0
    M_APP1  = 0xe1
    M_APP2  = 0xe2
    M_APP3  = 0xe3
    M_APP4  = 0xe4
    M_APP5  = 0xe5
    M_APP6  = 0xe6
    M_APP7  = 0xe7
    M_APP8  = 0xe8
    M_APP9  = 0xe9
    M_APP10 = 0xea
    M_APP11 = 0xeb
    M_APP12 = 0xec
    M_APP13 = 0xed
    M_APP14 = 0xee
    M_APP15 = 0xef
    M_COM   = 0xFE # COMment
  end

  def self.extract(io : IO) : AIS::Image?
    ff_read = true
    image = nil

    loop do
      marker = self.next_marker io, ff_read
      ff_read = false

      case marker
      when Block::M_SOF0, Block::M_SOF1, Block::M_SOF2, Block::M_SOF3, Block::M_SOF5, Block::M_SOF6, Block::M_SOF7,
           Block::M_SOF9, Block::M_SOF10, Block::M_SOF11, Block::M_SOF13, Block::M_SOF14, Block::M_SOF15
        if image.nil?
          io.read_bytes UInt16, IO::ByteFormat::BigEndian

          bits = io.read_byte.not_nil!
          height = io.read_bytes UInt16, IO::ByteFormat::BigEndian
          width = io.read_bytes UInt16, IO::ByteFormat::BigEndian
          channels = io.read_byte.not_nil!

          return Image.new width, height, :jpeg, bits, channels
        elsif !self.skip_variable(io)
          return image.unsafe_as(Image)
        end

        next
      when Block::M_APP0, Block::M_APP1, Block::M_APP2, Block::M_APP3, Block::M_APP4, Block::M_APP5, Block::M_APP6, Block::M_APP7,
           Block::M_APP8, Block::M_APP9, Block::M_APP10, Block::M_APP11, Block::M_APP12, Block::M_APP13, Block::M_APP14, Block::M_APP15
        if !self.skip_variable(io)
          return image.unsafe_as(Image)
        end

        next
      when Block::M_SOS, Block::M_EOI then return image.unsafe_as(Image)
      else
        if !self.skip_variable(io)
          return image.unsafe_as(Image)
        end
      end
    end

    image.unsafe_as(Image)
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 3] == SIGNATURE
  end

  private def self.next_marker(io : IO, ff_read : Bool) : Block
    if !ff_read
      extraneous = 0

      while (marker = io.read_byte) != 0xff
        return Block::M_EOI if marker.nil?
        extraneous += 1
      end
    end

    a = 1

    marker = nil

    loop do
      marker = io.read_byte

      return Block::M_EOI if marker.nil?

      a += 1

      break if marker != 0xff
    end

    if a < 2
      return Block::M_EOI
    end

    Block.new marker.not_nil!
  end

  private def self.skip_variable(io : IO) : Bool
    length = io.read_bytes UInt16, IO::ByteFormat::BigEndian

    if length < 2
      return false
    end

    length -= 2

    io.pos += length

    true
  end
end
