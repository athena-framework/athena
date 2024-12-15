# An `ACON::Output::Interface` implementation that wraps an [IO](https://crystal-lang.org/api/IO.html).
class Athena::Console::Output::IO < Athena::Console::Output
  property io : ::IO

  delegate :to_s, to: @io

  def initialize(
    @io : ::IO,
    verbosity : ACON::Output::Verbosity? = :normal,
    decorated : Bool? = nil,
    formatter : ACON::Formatter::Interface? = nil,
  )
    decorated = self.has_color_support? if decorated.nil?

    super verbosity, decorated, formatter
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    message += EOL if new_line

    @io.print message
  end

  private def io_do_write(message : String, new_line : Bool) : Nil
    message += EOL if new_line

    @io.print message
  end

  private def has_color_support? : Bool
    # Respect https://no-color.org.
    return false if ENV["NO_COLOR"]?.presence

    # Respect https://force-color.org.
    return true if ENV["FORCE_COLOR"]?.presence

    if "Hyper" == ENV["TERM_PROGRAM"]? ||
       ENV.has_key?("COLORTERM") ||
       ENV.has_key?("ANSICON") ||
       "ON" == ENV["ConEmuANSI"]?
      return true
    end

    return @io.tty? unless term = ENV["TERM"]?

    return false if "dumb" == term

    # See https://github.com/chalk/supports-color/blob/d4f413efaf8da045c5ab440ed418ef02dbb28bf1/index.js#L157
    term.matches? /^((screen|xterm|vt100|vt220|putty|rxvt|ansi|cygwin|linux).*)|(.*-256(color)?(-bce)?)$/
  end
end
