class FooCommand < IOCommand
  protected def configure : Nil
    self
      .name("foo:bar")
      .description("The foo:bar command")
      .aliases("afoobar")
  end

  protected def interact(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
    output.puts "interact called"
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts "execute called"

    super
  end
end
