# Represents a type responsible for guessing the MIME type of a file.
module Athena::MIME::TypesGuesserInterface
  # Returns `true` if this guesser is supported, otherwise `false`.
  #
  # The value may be cached on the class level.
  abstract def supported? : Bool

  # Returns the guessed MIME type for the file at the provided *path*,
  # or `nil` if it could not be determined.
  #
  # How exactly the MIME type is determined is up to each individual implementation.
  #
  # ```
  # guesser.guess_mime_type "/path/to/image.png" # => "image/png"
  # ```
  abstract def guess_mime_type(path : String | Path) : String?
end
