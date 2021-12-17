class TestCommand < ACON::Command
  protected def configure : Nil
    self
      .name("namespace:name")
      .description("description")
      .aliases("name")
      .help("help")
  end

  protected def interact(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
    output.puts "interact called"
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts "execute called"

    ACON::Command::Status::SUCCESS
  end
end
