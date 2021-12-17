# `Athena::Console` uses a dedicated interface for representing an output destination.
# This allows it to have multiple more specialized implementations as opposed to
# being tightly coupled to `STDOUT` or a raw [IO](https://crystal-lang.org/api/IO.html).
# This interface represents the methods that _must_ be implemented, however implementations can add additional functionality.
#
# The most common implementations include `ACON::Output::ConsoleOutput` which is based on `STDOUT` and `STDERR`,
# and `ACON::Output::Null` which can be used when you want to silent all output, such as for tests.
#
# Each output's `ACON::Output::Verbosity` and output `ACON::Output::Type` can also be configured on a per message basis.
module Athena::Console::Output::Interface
  # Outputs the provided *message* followed by a new line.
  # The *verbosity* and/or *output_type* parameters can be used to control when and how the *message* is printed.
  abstract def puts(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil

  # Outputs the provided *message*.
  # The *verbosity* and/or *output_type* parameters can be used to control when and how the *message* is printed.
  abstract def print(message : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil

  # Returns the minimum `ACON::Output::Verbosity` required for a message to be printed.
  abstract def verbosity : ACON::Output::Verbosity

  # Set the minimum `ACON::Output::Verbosity` required for a message to be printed.
  abstract def verbosity=(verbosity : ACON::Output::Verbosity) : Nil

  # Returns `true` if printed messages should have their decorations applied.
  # I.e. `ACON::Formatter::OutputStyleInterface`.
  abstract def decorated? : Bool

  # Sets if printed messages should be *decorated*.
  abstract def decorated=(decorated : Bool) : Nil

  # Returns the `ACON::Formatter::Interface` used by `self`.
  abstract def formatter : ACON::Formatter::Interface

  # Sets the `ACON::Formatter::Interface` used by `self`.
  abstract def formatter=(formatter : ACON::Formatter::Interface) : Nil
end
