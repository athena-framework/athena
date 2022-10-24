@[ACONA::AsCommand("annotation:configured", description: "Command configured via annotation", aliases: ["ac"])]
class AnnotationConfiguredCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
