require "./interface"

# Extension of `ACON::Formatter::Interface` that supports word wrapping.
module Athena::Console::Formatter::WrappableInterface
  include Athena::Console::Formatter::Interface

  # Formats the provided *message* according to the defined styles, wrapping it at the provided *width*.
  # A width of `0` means no wrapping.
  abstract def format_and_wrap(message : String?, width : Int32) : String
end
