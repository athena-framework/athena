class FooHiddenCommand < ACON::Command
  protected def configure : Nil
    self
      .name("foo:hidden")
      .aliases("afoohidden")
      .hidden(true)
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
