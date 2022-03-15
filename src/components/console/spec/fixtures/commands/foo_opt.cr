class FooOptCommand < IOCommand
  protected def configure : Nil
    self
      .name("foo:bar")
      .description("The foo:bar command")
      .aliases("afoobar")
      .option("fooopt", "f", :optional, "fooopt description")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    super

    self.output.puts "execute called"
    self.output.puts input.option("fooopt")

    ACON::Command::Status::SUCCESS
  end
end
