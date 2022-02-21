struct Athena::ImageSize::Extractors::SVG < Athena::ImageSize::Extractors::Extractor
  private SVG_FORMAT = /<svg\b([^>]*)>/
  private XML_FORMAT = /<\?xml|<!--/

  # Based on https://github.com/php/php-src/blob/95da6e807a948039d3a42defbd849c4fed6cbe35/ext/standard/image.c#L100.
  def self.extract(io : IO) : AIS::Image?
    contents = Bytes.new 4096
    io.read_fully? contents
    contents = String.new contents

    attributes = Hash(String, String?).new

    svg_tag = contents[0, 1024][SVG_FORMAT, 1]? || contents[0, 4096][SVG_FORMAT, 1]

    svg_tag.scan(/(\S+)=(?:'([^']*)'|"([^"]*)"|([^'"\s]*))/) do |match|
      attributes[match[1]] = match[2]? || match[3]? || match[4]?
    end

    width = height = 0

    if w = attributes["width"]?
      width = self.parse_length w
    end

    if h = attributes["height"]?
      height = self.parse_length h
    end

    Image.new width.not_nil!, height.not_nil!, :svg
  end

  def self.matches?(io : IO, bytes : Bytes) : Bool
    contents = String.new bytes

    SVG_FORMAT.matches?(contents) || (XML_FORMAT.matches?(contents) && SVG_FORMAT.matches?(contents))
  end

  private def self.parse_length(length : String) : Int32
    pixels = case length.downcase.strip[/(?:em|ex|px|in|cm|mm|pt|pc|%)\z/]?
             when "em", "ex", "%" then nil
             when "in"            then length.to_f(strict: false) * AIS.dpi
             when "cm"            then length.to_f(strict: false) * AIS.dpi / 2.54
             when "mm"            then length.to_f(strict: false) * AIS.dpi / 25.4
             when "pt"            then length.to_f(strict: false) * AIS.dpi / 72
             when "pc"            then length.to_f(strict: false) * AIS.dpi / 6
             else                      length.to_f(strict: false)
             end

    if pixels
      pixels.round.to_i
    else
      0
    end
  end
end
