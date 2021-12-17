class FooWithoutAliasCommand < IOCommand
  protected def configure : Nil
    self
      .name("foo")
      .description("The foo command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts "execute called"

    ACON::Command::Status::SUCCESS
  end
end
