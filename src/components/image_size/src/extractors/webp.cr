struct Athena::ImageSize::Extractors::WebP < Athena::ImageSize::Extractors::Extractor
  private RIFF_SIGNATURE = Bytes['R'.ord, 'I'.ord, 'F'.ord, 'F'.ord, read_only: true]
  private WEBP_SIGNATURE = Bytes['W'.ord, 'E'.ord, 'B'.ord, 'P'.ord, read_only: true]
  private SIGNATURE      = Bytes['V'.ord, 'P'.ord, '8'.ord, read_only: true]

  private enum Format
    Lossy    = 0x20
    Lossless = 0x4c
    Extended = 0x58
  end

  # Based on https://github.com/php/php-src/blob/95da6e807a948039d3a42defbd849c4fed6cbe35/ext/standard/image.c#L100.
  def self.extract(io : IO) : AIS::Image?
    buffer = Bytes.new 18
    io.read_fully buffer

    return unless buffer[0, 3] == SIGNATURE

    return unless format = Format.from_value? buffer[3]

    width, height = case format
                    in .lossless?
                      {
                        (buffer[9] + ((buffer[10] & 0x3F) << 8) + 1),
                        ((buffer[10] >> 6) + (buffer[11] << 2) + ((buffer[12] & 0xF) << 10) + 1),
                      }
                    in .lossy?
                      {
                        (buffer[14] + ((buffer[15] & 0x3F) << 8)),
                        (buffer[16] + ((buffer[17] & 0x3F) << 8)),
                      }
                    in .extended?
                      {
                        (buffer[12] + (buffer[13] << 8) + (buffer[14] << 16) + 1),
                        (buffer[15] + (buffer[16] << 8) + (buffer[17] << 16) + 1),
                      }
                    end

    Image.new width, height, :webp, 8
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    bytes[0, 4] == RIFF_SIGNATURE && bytes[8, 4] == WEBP_SIGNATURE
  end
end
