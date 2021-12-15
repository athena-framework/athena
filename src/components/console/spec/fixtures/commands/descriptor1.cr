class DescriptorCommand1 < ACON::Command
  protected def configure : Nil
    self
      .name("descriptor:command1")
      .aliases("alias1", "alias2")
      .description("command 1 description")
      .help("command 1 help")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
