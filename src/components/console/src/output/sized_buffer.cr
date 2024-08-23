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
    if @max_length < 0
      raise ACON::Exception::InvalidArgument.new "'#{self.class}#max_length' must be a positive, got: '#{@max_length}'."
    end

    super verbosity, decorated, formatter
  end

  def fetch : String
    content = @buffer

    @buffer = ""

    content
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    @buffer += message

    @buffer += EOL if new_line

    @buffer = @buffer.chars.last(@max_length).join
  end
end
