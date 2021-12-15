require "./interface"

# Common base implementation of `ACON::Output::Interface`.
abstract class Athena::Console::Output
  include Athena::Console::Output::Interface

  @formatter : ACON::Formatter::Interface
  @verbosity : ACON::Output::Verbosity

  def initialize(
    verbosity : ACON::Output::Verbosity? = :normal,
    decorated : Bool = false,
    formatter : ACON::Formatter::Interface? = nil
  )
    @verbosity = verbosity || ACON::Output::Verbosity::NORMAL
    @formatter = formatter || ACON::Formatter::Output.new
    @formatter.decorated = decorated
  end

  # :inherit:
  def verbosity : ACON::Output::Verbosity
    @verbosity
  end

  # :inherit:
  def verbosity=(@verbosity : ACON::Output::Verbosity) : Nil
  end

  # :inherit:
  def formatter : ACON::Formatter::Interface
    @formatter
  end

  # :inherit:
  def formatter=(@formatter : ACON::Formatter::Interface) : Nil
  end

  # :inherit:
  def decorated? : Bool
    @formatter.decorated?
  end

  # :inherit:
  def decorated=(decorated : Bool) : Nil
    @formatter.decorated = decorated
  end

  # :inherit:
  def puts(*messages : String) : Nil
    self.puts messages
  end

  # :inherit:
  def puts(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    self.write message, true, verbosity, output_type
  end

  # :inherit:
  def puts(message : _, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    self.puts message.to_s, verbosity, output_type
  end

  # :inherit:
  def print(*messages : String) : Nil
    self.print messages
  end

  # :inherit:
  def print(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    self.write message, false, verbosity, output_type
  end

  # :inherit:
  def print(message : _, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    self.print message.to_s, verbosity, output_type
  end

  protected def write(
    message : String | Enumerable(String),
    new_line : Bool,
    verbosity : ACON::Output::Verbosity,
    output_type : ACON::Output::Type
  )
    messages = message.is_a?(String) ? {message} : message

    return if verbosity > self.verbosity

    messages.each do |m|
      self.do_write(
        case output_type
        in .normal? then @formatter.format m
        in .plain?  then @formatter.format(m).gsub(/(?:<\/?[^>]*>)|(?:<!--(.*?)-->[\n]?)/, "") # TODO: Use a more robust strip_tags implementation.
        in .raw?    then m
        end,
        new_line
      )
    end
  end

  protected abstract def do_write(message : String, new_line : Bool) : Nil
end
