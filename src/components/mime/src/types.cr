require "./types/data"
require "./types_interface"

# Default implementation of `AMIME::TypesInterface`.
#
# Also supports guessing a MIME type based on a given file path.
# Custom guessers can be registered via the `#register_guesser` method.
# Custom guessers are always called before any default ones.
#
# ```
# mime_types = AMIME::Types.new
#
# mime_types.mime_types "png"                     # => {"image/png", "image/apng", "image/vnd.mozilla.apng"}
# mime_types.extensions "image/png"               # => {"png"}
# mime_types.guess_mime_type "/path/to/image.png" # => "image/png"
# ```
class Athena::MIME::Types
  include Athena::MIME::TypesInterface

  # :nodoc:
  #
  # Key: MIME Type, Value: Array of extensions
  alias Map = Hash(String, Array(String))

  # Returns/sets the default singleton instance.
  class_property default : self { new }

  @extensions = Map.new { |hash, key| hash[key] = [] of String }
  @mime_types = Map.new { |hash, key| hash[key] = [] of String }
  @guessers : Array(AMIME::TypesGuesserInterface) = [] of AMIME::TypesGuesserInterface

  def initialize(map : Hash(String, Enumerable(String)) = Map.new)
    map.each do |mime_type, extensions|
      @extensions[mime_type] = extensions.to_a

      extensions.each do |ext|
        @mime_types[ext] << mime_type
      end
    end

    self.register_guesser AMIME::MagicTypesGuesser.new
  end

  # Registers the provided *guesser*.
  # The last registered guesser is preferred over previously registered ones.
  def register_guesser(guesser : AMIME::TypesGuesserInterface) : Nil
    @guessers.unshift guesser
  end

  # :inherit:
  def extensions(for mime_type : String) : Enumerable(String)
    extensions = @extensions[mime_type]? || @extensions[lower_case_mime_type = mime_type.downcase]?

    extensions || MAP[mime_type]? || MAP[lower_case_mime_type || mime_type.downcase]? || [] of String
  end

  # :inherit:
  def mime_types(for extension : String) : Enumerable(String)
    mime_types = @mime_types[extension]? || @mime_types[lower_case_extension = extension.downcase]?

    mime_types || REVERSE_MAP[extension]? || REVERSE_MAP[lower_case_extension || extension.downcase]? || [] of String
  end

  # :inherit:
  def supported? : Bool
    @guessers.any? &.supported?
  end

  # :inherit:
  def guess_mime_type(path : String | Path) : String?
    @guessers.each do |guesser|
      next unless guesser.supported?

      if guess = guesser.guess_mime_type path
        return guess
      end
    end

    unless self.supported?
      raise AMIME::Exception::Logic.new "Unable to guess the MIME type as no guessers are available."
    end

    nil
  end
end
