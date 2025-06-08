require "./types_guesser_interface"
require "mime"

# A `AMIME::TypesGuesserInterface` implementation based Crystal's [MIME](https://crystal-lang.org/api/MIME.html) module.
#
# This guesser is mainly intended as a fallback for when `AMIME::MagicTypesGuesser` isn't available (MSVC Windows).
struct Athena::MIME::NativeTypesGuesser
  include Athena::MIME::TypesGuesserInterface

  # :inherit:
  def supported? : Bool
    true
  end

  # :inherit:
  #
  # NOTE: Guessing is based solely on the extension of the provided *path*.
  def guess_mime_type(path : String | Path) : String?
    if !File.file?(path) || !File::Info.readable?(path)
      raise AMIME::Exception::InvalidArgument.new "The file '#{path}' does not exist or is not readable."
    end

    ::MIME.from_filename? path
  end
end
