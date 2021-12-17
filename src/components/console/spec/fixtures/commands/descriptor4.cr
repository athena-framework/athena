class DescriptorCommand4 < ACON::Command
  protected def configure : Nil
    self
      .name("descriptor:command4")
      .aliases("descriptor:alias_command4", "command4:descriptor")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
