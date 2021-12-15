# An extension of `ACON::Input::Interface` that supports input stream [IOs](https://crystal-lang.org/api/IO.html).
#
# Allows customizing where the input data is read from.
# Defaults to `STDIN`.
module Athena::Console::Input::Streamable
  include Athena::Console::Input::Interface

  # Returns the input stream.
  abstract def stream : IO?

  # Sets the input stream.
  abstract def stream=(@stream : IO?)
end
