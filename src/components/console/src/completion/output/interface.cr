require "../suggestions"

# :nodoc:
module Athena::Console::Completion::Output
  abstract struct Interface
    # Returns a string representation of the args passed to the command.
    abstract def write(suggestions : ACON::Completion::Suggestions, output : ACON::Output::Interface) : Nil
  end
end
