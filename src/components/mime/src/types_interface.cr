require "./types_guesser_interface"

# Represents a type responsible for managing MIME types and file extensions.
module Athena::MIME::TypesInterface
  include Athena::MIME::TypesGuesserInterface

  # Returns the valid file extensions for the provided *mime_type* in decreasing order of preference.
  #
  # ```
  # types.extensions "image/png" # => {"png"}
  # ```
  abstract def extensions(for mime_type : String) : Enumerable(String)

  # Returns the valid MIME types for the provided *extension* in decreasing order of preference.
  #
  # ```
  # types.mime_types "png" # => {"image/png", "image/apng", "image/vnd.mozilla.apng"}
  # ```
  abstract def mime_types(for extension : String) : Enumerable(String)
end
