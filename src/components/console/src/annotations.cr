module Athena::Console::Annotations
  # Annotation containing metadata related to an `ACON::Command`.
  # This is the preferred way of configuring a command as it enables lazy command instantiation when used within the Athena framework.
  # Checkout the [external documentation](../../../architecture/console.md) for more information.
  #
  # ```
  # @[ACONA::AsCommand("add", description: "Sums two numbers, optionally making making the sum negative")]
  # class AddCommand < ACON::Command
  #   # ...
  # end
  # ```
  #
  # ## Configuration
  #
  # Various fields can be used within this annotation to control various aspects of the command.
  # All fields are optional unless otherwise noted.
  #
  # ### name
  #
  # **Type:** `String` - **required**
  #
  # The name of the command.
  # May be provided as either an explicit named argument, or the first positional argument.
  # See `ACON::Command#name`.
  #
  # ### description
  #
  # **Type:** `String`
  #
  # A short sentence describing the function of the command.
  # See `ACON::Command#description`.
  #
  # ### hidden
  #
  # **Type:** `Bool`
  #
  # If this command should be hidden from the command list.
  # See `ACON::Command#hidden?`.
  #
  # ### aliases
  #
  # **Type:** `Enumerable(String)`
  #
  # Alternate names this command may be invoked by.
  # See `ACON::Command#aliases`.
  annotation AsCommand; end
end
