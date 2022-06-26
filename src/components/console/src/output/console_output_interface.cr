require "./interface"

# Extension of `ACON::Output::Interface` that adds additional functionality for terminal based outputs.
module Athena::Console::Output::ConsoleOutputInterface
  # include Athena::Console::Output::Interface

  # Returns an `ACON::Output::Interface` that represents `STDERR`.
  abstract def error_output : ACON::Output::Interface

  # Sets the `ACON::Output::Interface` that represents `STDERR`.
  abstract def error_output=(stderr : ACON::Output::Interface) : Nil

  abstract def section : ACON::Output::Section
end
