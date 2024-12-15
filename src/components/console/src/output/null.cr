require "./interface"

# An `ACON::Output::Interface` that does not output anything, such as for tests.
class Athena::Console::Output::Null
  include Athena::Console::Output::Interface

  @formatter : ACON::Formatter::Interface? = nil

  # :inherit:
  def puts(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
  end

  # :inherit:
  def print(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
  end

  def puts(message, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
  end

  def print(message, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
  end

  # :inherit:
  def verbosity : ACON::Output::Verbosity
    ACON::Output::Verbosity::SILENT
  end

  # :inherit:
  def verbosity=(verbosity : ACON::Output::Verbosity) : Nil
  end

  # :inherit:
  def decorated=(decorated : Bool) : Nil
  end

  # :inherit:
  def decorated? : Bool
    false
  end

  # :inherit:
  def formatter : ACON::Formatter::Interface
    @formatter ||= ACON::Formatter::Null.new
  end

  # :inherit:
  def formatter=(formatter : ACON::Formatter::Interface) : Nil
  end
end
