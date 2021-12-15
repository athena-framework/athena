class Foo6Command < ACON::Command
  protected def configure : Nil
    self
      .name("0foo:bar")
      .description("0foo:bar command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
