class ClassVarConfiguredCommand < ACON::Command
  @@default_name = "class:var:configured"
  @@default_description = "Command configured via class vars"

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
