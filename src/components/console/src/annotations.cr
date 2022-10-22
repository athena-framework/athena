module Athena::Console::Annotations
  # Annotation containing metadata related to an `ACON::Command`.
  # This is the preferred way of configuring a command as it enables lazy command instantiation when used within the Athena framework.
  # Checkout the [external documentation](/components/console/) for more information.
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
  # The name of the command. May be provided as either an explicit named argument, or the first positional argument.
  #
  # ### description
  #
  # **Type:** `String`
  #
  # A short sentence describing the function of the command.
  annotation AsCommand; end
end
