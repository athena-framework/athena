class BarBucCommand < ACON::Command
  protected def configure : Nil
    self
      .name("bar:buc")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end
