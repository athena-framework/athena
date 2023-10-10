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
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Otherwise, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-image_size:
#     github: athena-framework/image-size
#     version: ~> 0.1.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-image_size"`.
#
# From here you can use `AIS::Image` as needed.
module Athena::ImageSize
  VERSION = "0.1.2"

  # Represents the [DPI (Dots Per Inch)](https://en.wikipedia.org/wiki/Dots_per_inch) used to calculate dimensions of `AIS::Image::Format::SVG` images, defaulting to `72.0`.
  class_property dpi : Float64 = 72.0

  # :nodoc:
  module Extractors; end
end
