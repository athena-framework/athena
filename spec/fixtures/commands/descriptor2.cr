class DescriptorCommand2 < ACON::Command
  protected def configure : Nil
    self
      .name("descriptor:command2")
      .description("command 2 description")
      .help("command 2 help")
      .usage("-o|--option_name <argument_name>")
      .usage("<argument_name>")
      .argument("argument_name", :required)
      .option("option_name", "o", :none)
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
