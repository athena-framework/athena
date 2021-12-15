class FooSameCaseUppercaseCommand < ACON::Command
  protected def configure : Nil
    self
      .name("foo:BAR")
      .description("foo:BAR command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
