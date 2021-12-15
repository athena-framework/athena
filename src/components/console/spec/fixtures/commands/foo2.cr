class Foo2Command < IOCommand
  protected def configure : Nil
    self
      .name("foo1:bar")
      .description("The foo1:bar command")
      .aliases("afoobar2")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
