require "./interface"

# Base implementation of `ACON::Style::Interface` and `ACON::Output::Interface` that provides logic common to all styles.
abstract class Athena::Console::Style::Output
  include Athena::Console::Style::Interface
  include Athena::Console::Output::Interface

  @output : ACON::Output::Interface

  def initialize(@output : ACON::Output::Interface); end

  # See `ACON::Output::Interface#decorated?`.
  def decorated? : Bool
    @output.decorated?
  end

  # See `ACON::Output::Interface#decorated=`.
  def decorated=(decorated : Bool) : Nil
    @output.decorated = decorated
  end

  # See `ACON::Output::Interface#formatter`.
  def formatter : ACON::Formatter::Interface
    @output.formatter
  end

  # See `ACON::Output::Interface#formatter=`.
  def formatter=(formatter : ACON::Formatter::Interface) : Nil
    @output.formatter = formatter
  end

  # :inherit:
  def new_line(count : Int32 = 1) : Nil
    @output.print "\n" * count
  end

  # See `ACON::Output::Interface#puts`.
  def puts(message, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    @output.puts message, verbosity, output_type
  end

  # See `ACON::Output::Interface#print`.
  def print(message, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    @output.print message, verbosity, output_type
  end

  # See `ACON::Output::Interface#verbosity`.
  def verbosity : ACON::Output::Verbosity
    @output.verbosity
  end

  # See `ACON::Output::Interface#verbosity=`.
  def verbosity=(verbosity : ACON::Output::Verbosity) : Nil
    @output.verbosity = verbosity
  end

  protected def error_output : ACON::Output::Interface
    unless (output = @output).is_a? ACON::Output::ConsoleOutputInterface
      return @output
    end

    output.error_output
  end
end
