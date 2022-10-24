@[ACONA::AsCommand("annotation:configured", hidden: true)]
class AnnotationConfiguredHiddenFieldCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
