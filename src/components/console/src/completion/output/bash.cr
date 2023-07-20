struct Athena::Console::Completion::Output::Bash < Athena::Console::Completion::OutputInterface
  def write(suggestions : ACON::Completion::Suggestions, output : ACON::Output::Interface) : Nil
  end
end
