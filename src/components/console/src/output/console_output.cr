abstract class Athena::Console::Output; end

require "./console_output_interface"
require "./io"

# An `ACON::Output::ConsoleOutputInterface` that wraps `STDOUT` and `STDERR`.
class Athena::Console::Output::ConsoleOutput < Athena::Console::Output::IO
  include Athena::Console::Output::ConsoleOutputInterface

  # Sets the `ACON::Output::Interface` that represents `STDERR`.
  setter stderr : ACON::Output::Interface
  @console_section_outputs = Array(ACON::Output::Section).new

  def initialize(
    verbosity : ACON::Output::Verbosity = :normal,
    decorated : Bool? = nil,
    formatter : ACON::Formatter::Interface? = nil,
  )
    super STDOUT, verbosity, decorated, formatter

    @stderr = ACON::Output::IO.new STDERR, verbosity, decorated, @formatter
    actual_decorated = self.decorated?

    if decorated.nil?
      self.decorated = actual_decorated && @stderr.decorated?
    end
  end

  # :inherit:
  def section : ACON::Output::Section
    ACON::Output::Section.new(
      self.io,
      @console_section_outputs,
      self.verbosity,
      self.decorated?,
      self.formatter
    )
  end

  # :inherit:
  def error_output : ACON::Output::Interface
    @stderr
  end

  # :inherit:
  def error_output=(@stderr : ACON::Output::Interface) : Nil
  end

  # :inherit:
  def decorated=(decorated : Bool) : Nil
    super
    @stderr.decorated = decorated
  end

  # :inherit:
  def formatter=(formatter : Bool) : Nil
    super
    @stderr.formatter = formatter
  end

  # :inherit:
  def verbosity=(verbosity : ACON::Output::Verbosity) : Nil
    super
    @stderr.verbosity = verbosity
  end
end
