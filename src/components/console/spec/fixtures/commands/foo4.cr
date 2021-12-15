class Foo4Command < ACON::Command
  protected def configure : Nil
    self
      .name("foo3:bar:toh")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
