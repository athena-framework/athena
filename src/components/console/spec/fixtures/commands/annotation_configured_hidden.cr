@[ACONA::AsCommand("|annotation:configured")]
class AnnotationConfiguredHiddenCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
