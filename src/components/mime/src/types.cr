require "./types/data"
require "./types_interface"

class Athena::MIME::Types
  include Athena::MIME::TypesInteface

  # Key: MIME Type, Value: Array of extensions
  alias Map = Hash(String, Array(String))

  class_getter default : self { new }

  @extensions = Map.new
  @mime_types = Map.new
  @guessers : Array(AMIME::TypesGuesserInterface) = [] of AMIME::TypesGuesserInterface

  def initialize(map : Map = Map.new)
    map.each do |mime_type, extensions|
      @extensions[mime_type] = extensions

      extensions.each do |ext|
        @mime_types[extensions] << mime_type
      end
    end

    self.register_guesser AMIME::MagicTypesGuesser.new
  end

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
