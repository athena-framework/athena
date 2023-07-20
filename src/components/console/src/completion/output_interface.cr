require "./suggestions"

abstract struct Athena::Console::Completion::OutputInterface
  # Returns a string representation of the args passed to the command.
  abstract def write(suggestions : ACON::Completion::Suggestions, output : ACON::Output::Interface) : Nil
end
