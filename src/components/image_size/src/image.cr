# Represents information related to a processed image.
#
# ```
# pp AIS::Image.from_file_path "spec/images/jpeg/436x429_8_3.jpeg" # =>
# # Athena::ImageSize::Image(
# # @bits=8,
# # @channels=3,
# # @format=JPEG,
# # @height=429,
# # @width=436)
# ```
struct Athena::ImageSize::Image
  # Returns the width of this image in pixels.
  getter width : Int32

  # Returns the width of this image in pixels.
  getter height : Int32

  # Returns the number of [bits per pixel](https://en.wikipedia.org/wiki/Color_depth) within this image, if available.
  getter bits : Int32?

  # Returns the number of [channels](https://en.wikipedia.org/wiki/Channel_(digital_image)) within this image, if available.
  getter channels : Int32?

  # Returns the format of this image.
  getter format : Athena::ImageSize::Image::Format

  protected def initialize(width : Int, height : Int, @format : AIS::Image::Format, bits : Int? = nil, channels : Int? = nil)
    @width = width.to_i
    @height = height.to_i
    @bits = bits.try &.to_i
    @channels = channels.try &.to_i
  end

  # Attempts to process the image at the provided *path*,
  # raising an exception if either the images fails to process or is an unsupported format.
  def self.from_file_path(path : String | Path) : self
    self.from_io File.open path
  end

  # Attempts to process the image at the provided *path*,
  # returning `nil` if either the images fails to process or is an unsupported format.
  def self.from_file_path?(path : String | Path) : self?
    self.from_io? File.open path
  end

  # Attempts to process the image from the provided *io*,
  # raising an exception if either the images fails to process or is an unsupported format.
  def self.from_io(io : IO) : self
    if extractor_type = AIS::Extractors::Extractor.from_io io
      return extractor_type.extract(io) || raise "Failed to parse image."
    end

    raise "Unsupported image format."
  end

  # Attempts to process the image from the provided *io*,
  # returning `nil` if either the images fails to process or is an unsupported format.
  def self.from_io?(io : IO) : self?
    if extractor_type = AIS::Extractors::Extractor.from_io io
      return extractor_type.extract io
    end
  ensure
    io.close
  end

  # Returns a tuple of this images size in the format of `{width, height}`.
  def size : Tuple(Int32, Int32)
    {@width, @height}
  end
end
