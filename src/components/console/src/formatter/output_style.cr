require "colorize"
require "./output_style_interface"

# Default implementation of `ACON::Formatter::OutputStyleInterface`.
struct Athena::Console::Formatter::OutputStyle
  include Athena::Console::Formatter::OutputStyleInterface

  # :inherit:
  setter foreground : Colorize::Color = :default

  # :inherit:
  setter background : Colorize::Color = :default

  # :inherit:
  setter options : Colorize::Mode = :none

  # Sets the `href` that `self` should link to.
  setter href : String? = nil

  # :nodoc:
  getter? handles_href_gracefully : Bool do
    "JetBrains-JediTerm" != ENV["TERMINAL_EMULATOR"]? && (!ENV.has_key?("KONSOLE_VERSION") || ENV["KONSOLE_VERSION"].to_i > 201_100)
  end

  def initialize(foreground : Colorize::Color | String = :default, background : Colorize::Color | String = :default, @options : Colorize::Mode = :none)
    self.foreground = foreground
    self.background = background
  end

  # :inherit:
  def add_option(option : Colorize::Mode) : Nil
    @options |= option
  end

  # :ditto:
  def add_option(option : String) : Nil
    self.add_option Colorize::Mode.parse option
  end

  # :inherit:
  def background=(color : String)
    if hex_value = color.lchop? '#'
      r, g, b = hex_value.hexbytes
      return @background = Colorize::ColorRGB.new r, g, b
    end

    @background = Colorize::ColorANSI.parse color
  end

  # :inherit:
  def foreground=(foreground : String)
    if hex_value = foreground.lchop? '#'
      r, g, b = hex_value.hexbytes
      return @foreground = Colorize::ColorRGB.new r, g, b
    end

    @foreground = Colorize::ColorANSI.parse foreground
  end

  # :inherit:
  def remove_option(option : Colorize::Mode) : Nil
    @options ^= option
  end

  # :ditto:
  def remove_option(option : String) : Nil
    self.remove_option Colorize::Mode.parse option
  end

  # :inherit:
  def apply(text : String) : String
    if (href = @href) && self.handles_href_gracefully?
      text = "\e]8;;#{href}\e\\#{text}\e]8;;\e\\"
    end

    return text if self.default?

    apply_color text
  end

  # TODO: Remove methods below when/if https://github.com/crystal-lang/crystal/pull/16052 is merged/released.
  # Should then bump min crystal version.

  private def apply_color(text : String) : String
    String.build do |io|
      printed = false

      io << "\e["

      unless @foreground == Colorize::ColorANSI::Default
        @foreground.fore io
        printed = true
      end

      unless @background == Colorize::ColorANSI::Default
        io << ';' if printed
        @background.back io
        printed = true
      end

      each_code(@options) do |flag|
        io << ';' if printed
        io << flag
        printed = true
      end

      io << 'm'

      io << text

      printed = false

      io << "\e["

      unless @foreground == Colorize::ColorANSI::Default
        io << ';' if printed
        io << 39
        printed = true
      end

      unless @background == Colorize::ColorANSI::Default
        io << ';' if printed
        io << 49
        printed = true
      end

      each_code(@options, true) do |flag|
        io << ';' if printed
        io << flag
        printed = true
      end

      io << 'm'
    end
  end

  private def default? : Bool
    @foreground == Colorize::ColorANSI::Default && @background == Colorize::ColorANSI::Default && @options.none?
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def each_code(mode : Colorize::Mode, unset : Bool = false, &)
    yield (unset ? "22" : "1") if mode.bold?
    yield (unset ? "22" : "2") if mode.dim?
    yield (unset ? "23" : "3") if mode.italic?
    yield (unset ? "24" : "4") if mode.underline?
    yield (unset ? "25" : "5") if mode.blink?
    yield (unset ? "26" : "6") if mode.blink_fast?
    yield (unset ? "27" : "7") if mode.reverse?
    yield (unset ? "28" : "8") if mode.hidden?
    yield (unset ? "29" : "9") if mode.strikethrough?
    yield (unset ? "24" : "21") if mode.double_underline?
    yield (unset ? "55" : "53") if mode.overline?
  end
end
