# :nodoc:
abstract struct Athena::ImageSize::Extractors::Extractor
  # ameba:disable Metrics/CyclomaticComplexity
  def self.from_io(io : IO)
    bytes = Bytes.new 3
    io.read_fully bytes

    return PNG if PNG.matches? io, bytes
    return JPEG if JPEG.matches? io, bytes
    return GIF if GIF.matches? io, bytes
    return BMP if BMP.matches? io, bytes
    return APNG if APNG.matches? io, bytes
    return SWF if SWF.matches? io, bytes

    # Read in an additionl bytes to determine the format.
    bytes = Bytes.new 4
    io.pos -= 3
    io.read_fully bytes

    return MMTIFF if MMTIFF.matches? io, bytes
    return IITIFF if IITIFF.matches? io, bytes
    return ICO if ICO.matches? io, bytes
    return CUR if CUR.matches? io, bytes
    return PSD if PSD.matches? io, bytes

    # Read in an additionl bytes to determine the format.
    bytes = Bytes.new 8
    io.pos -= 4
    io.read_fully bytes

    return MNG if MNG.matches? io, bytes

    # Read in an additionl bytes to determine the format.
    bytes = Bytes.new 12
    io.pos -= 8
    io.read_fully bytes

    return WebP if WebP.matches? io, bytes

    # Read in an additionl bytes to determine the format.
    # These are text based formats so will need to instantiate a string for the logic to work.
    # Being sure to rewind the IO.
    bytes = Bytes.new 4096
    io.pos -= 12
    io.read_fully? bytes

    io.rewind

    return SVG if SVG.matches? io, bytes

    nil
  end
end
