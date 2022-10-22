@[ACONA::AsCommand("class:var:configured", description: "Command configured via annotation")]
class ClassVarConfiguredCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
