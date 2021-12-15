# :nodoc:
class Athena::Console::Output::SizedBuffer < Athena::Console::Output
  @buffer : String = ""
  @max_length : Int32

  def initialize(
    @max_length : Int32,
    verbosity : ACON::Output::Verbosity? = :normal,
    decorated : Bool = false,
    formatter : ACON::Formatter::Interface? = nil
  )
    super verbosity, decorated, formatter
  end

  def fetch : String
    content = @buffer

    @buffer = ""

    content
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    @buffer += message

    @buffer += "\n" if new_line

    @buffer = @buffer.chars.last(@max_length).join
  end
end
