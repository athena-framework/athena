# :nodoc:
class Athena::Console::Formatter::NullStyle
  include Athena::Console::Formatter::OutputStyleInterface

  # :inherit:
  def foreground=(forground : Colorize::Color)
  end

  # :inherit:
  def background=(background : Colorize::Color)
  end

  # :inherit:
  def add_option(option : ACON::Formatter::Mode) : Nil
  end

  # :inherit:
  def remove_option(option : ACON::Formatter::Mode) : Nil
  end

  # :inherit:
  def apply(text : String) : String
    text
  end
end
