require "./extractor"

abstract struct Athena::ImageSize::Extractors::AbstractICO < Athena::ImageSize::Extractors::Extractor
  def self.extract(io : IO) : AIS::Image?
    num_icons = io.read_bytes UInt16

    width = 0
    height = 0
    bits = 0

    return if num_icons < 1 || num_icons > 255

    num_icons.times do
      icon_width = io.read_bytes UInt8
      icon_height = io.read_bytes UInt8

      # Skip color count
      io.skip 1

      # This bit must be `0`
      return unless io.read_bytes(UInt8).zero?

      # Skip color planes
      io.skip 2

      if (icon_bits = io.read_bytes UInt16) >= bits
        width, height, bits = icon_width, icon_height, icon_bits
      end
    end

    Image.new width.zero? ? 256 : width, height.zero? ? 256 : height, self.format, bits
  end
end
