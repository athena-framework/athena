class TestAmbiguousCommandRegistering2 < ACON::Command
  protected def configure : Nil
    self
      .name("test-ambiguous2")
      .description("The test-ambiguous2 command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts "test-ambiguous2"

    ACON::Command::Status::SUCCESS
  end
end
