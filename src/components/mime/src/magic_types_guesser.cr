require "./types_guesser_interface"

# A `AMIME::TypesGuesserInterface` implementation based on [libmagic](https://www.darwinsys.com/file/).
#
# Only natively supported on Unix systems and MSYS2 where the `file` package is easily installable.
# If you have the available lib files on Windows MSVC you may build with `-Dathena_use_libmagic` to explicitly enable the implementation.
struct Athena::MIME::MagicTypesGuesser
  include Athena::MIME::TypesGuesserInterface

  def initialize(
    @magic_file : String? = nil,
  ); end

  # As of now `libmagic` is only really supported on Unix and MSYS2.
  # Respect this by default, but also allow using a dedicated flag to enable just in case.
  {% if flag?("athena_use_libmagic") || flag?("unix") || (flag?("windows") && flag?("gnu")) %}
    @[Link("magic", pkg_config: "libmagic")]
    lib LibMagic
      type MagicT = Void*

      enum Flags
        MIME_TYPE = 0x000010 # Return the MIME type
      end

      fun magic_open(
        flags : LibC::Int,
      ) : MagicT

      fun magic_close(
        magic : MagicT,
      ) : Void

      fun magic_file(
        magic : MagicT,
        filename : LibC::Char*,
      ) : LibC::Char*

      fun magic_load(
        magic : MagicT,
        filename : LibC::Char*,
      ) : LibC::Int

      fun magic_error(
        magic : MagicT,
      ) : LibC::Char*
    end

    # :inherit:
    def supported? : Bool
      true
    end

    # :inherit:
    def guess_mime_type(path : String | Path) : String?
      if !File.file?(path) || !File::Info.readable?(path)
        raise AMIME::Exception::InvalidArgument.new "The file '#{path}' does not exist or is not readable."
      end

      unless self.supported?
        raise AMIME::Exception::Logic.new "The '#{self.class}' guesser is not supported."
      end

      unless magic = LibMagic.magic_open LibMagic::Flags::MIME_TYPE
        raise AMIME::Exception::Runtime.new "Failed to open libmagic."
      end

      begin
        magic_load = if magic_file = @magic_file
                       LibMagic.magic_load magic, magic_file
                     else
                       LibMagic.magic_load magic, nil
                     end

        unless magic_load.zero?
          raise AMIME::Exception::Runtime.new String.new LibMagic.magic_error magic
        end

        unless mime_type = LibMagic.magic_file magic, path.to_s
          raise AMIME::Exception::Runtime.new String.new LibMagic.magic_error magic
        end

        String.new mime_type
      ensure
        LibMagic.magic_close magic
      end
    end
  {% else %}
    # :inherit:
    def supported? : Bool
      false
    end

    # :inherit:
    def guess_mime_type(path : String | Path) : String?
      nil
    end
  {% end %}
end
