require "./image_format"
require "./extractors/*"
require "./image"

# Convenience alias to make referencing `Athena::ImageSize` types easier.
alias AIS = Athena::ImageSize

# The `Athena::ImageSize` component, `AIS` for short, allows creating an `AIS::Image` from various [image formats][Athena::ImageSize::Image::Format].
# The component has no dependencies and is framework agnostic.
#
# The image can be provided as a file path, or an `IO`, such as the response to an HTTP request.
# The image is processed byte by byte, so large images can be handled without loading the full image into memory.
#
# WARNING: This component is _NOT_ intended to check if a file is a valid image and may return nonsensical values if given a non-image file.
module Athena::ImageSize
  VERSION = "0.1.0"

  # Represents the [DPI (Dots Per Inch)](https://en.wikipedia.org/wiki/Dots_per_inch) used to calculate dimensions of `AIS::Image::Format::SVG` images, defaulting to `72.0`.
  class_property dpi : Float64 = 72.0

  # :nodoc:
  module Extractors; end
end
