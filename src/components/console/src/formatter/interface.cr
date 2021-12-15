require "./output_style_interface"

# A container that stores and applies `ACON::Formatter::OutputStyleInterface`.
# Is responsible for formatting outputted messages as per their styles.
module Athena::Console::Formatter::Interface
  # Sets if output messages should be decorated.
  abstract def decorated=(@decorated : Bool)

  # Returns `true` if output messages will be decorated, otherwise `false`.
  abstract def decorated? : Bool

  # Assigns the provided *style* to the provided *name*.
  abstract def set_style(name : String, style : ACON::Formatter::OutputStyleInterface) : Nil

  # Returns `true` if `self` has a style with the provided *name*, otherwise `false`.
  abstract def has_style?(name : String) : Bool

  # Returns an `ACON::Formatter::OutputStyleInterface` with the provided *name*.
  abstract def style(name : String) : ACON::Formatter::OutputStyleInterface

  # Formats the provided *message* according to the stored styles.
  abstract def format(message : String?) : String
end
