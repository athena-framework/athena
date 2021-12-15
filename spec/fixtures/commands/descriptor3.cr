class DescriptorCommand3 < ACON::Command
  protected def configure : Nil
    self
      .name("descriptor:command3")
      .description("command 3 description")
      .help("command 3 help")
      .hidden
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
