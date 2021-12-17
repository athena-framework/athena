class TestAmbiguousCommandRegistering < ACON::Command
  protected def configure : Nil
    self
      .name("test-ambiguous")
      .description("The test-ambiguous command")
      .aliases("test")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts "test-ambiguous"

    ACON::Command::Status::SUCCESS
  end
end
