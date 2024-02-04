# An `ACON::Output::Interface` implementation that wraps an [IO](https://crystal-lang.org/api/IO.html).
class Athena::Console::Output::IO < Athena::Console::Output
  property io : ::IO

  delegate :to_s, to: @io

  def initialize(
    @io : ::IO,
    verbosity : ACON::Output::Verbosity? = :normal,
    decorated : Bool? = nil,
    formatter : ACON::Formatter::Interface? = nil
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
    return false if "false" == ENV["NO_COLOR"]?
    return true if "Hyper" == ENV["TERM_PROGRAM"]?

    @io.tty?
  end
end
