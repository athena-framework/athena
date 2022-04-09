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
    "JetBrains-JediTerm" != ENV["TERMINAL_EMULATOR"]? && (!ENV.has_key?("KONSOLE_VERSION") || ENV["KONSOLE_VERSION"].to_i > 201100)
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
  def foreground=(color : String)
    if hex_value = color.lchop? '#'
      r, g, b = hex_value.hexbytes
      return @foreground = Colorize::ColorRGB.new r, g, b
    end

    @foreground = Colorize::ColorANSI.parse color
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

    color = Colorize::Object(String)
      .new(text)
      .fore(@foreground)
      .back(@background)

    if options = @options
      options.each do |mode|
        color.mode mode
      end
    end

    color.to_s
  end
end
