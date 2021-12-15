class Foo3Command < ACON::Command
  protected def configure : Nil
    self
      .name("foo3:bar")
      .description("The foo3:bar command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    begin
      begin
        raise Exception.new "First exception <p>this is html</p>"
      rescue ex
        raise Exception.new "Second exception <comment>comment</comment>", ex
      end
    rescue ex
      raise Exception.new "Third exception <fg=blue;bg=red>comment</>", ex
    end
  end
end
