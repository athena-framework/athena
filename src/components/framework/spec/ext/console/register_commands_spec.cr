require "../../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line, file: file
    require "../../spec_helper.cr"

    #{code}
  CR
end

private def assert_success(code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
  ASPEC::Methods.assert_success <<-CR, line: line, file: file
    require "../../spec_helper.cr"

    #{code}
  CR
end

@[ADI::Register]
class EagerlyInitializedCommand < ACON::Command
  class_getter initialized = false

  def initialize
    @@initialized = true
    super
  end

  protected def configure : Nil
    self
      .name("eagerly-initialized")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

@[ADI::Register]
@[ACONA::AsCommand("lazy-initialized")]
class LazyInitializedCommand < ACON::Command
  class_getter initialized = false

  def initialize
    @@initialized = true
    super
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

@[ADI::Register]
@[ACONA::AsCommand("annn|tset", hidden: true, description: "Test desc")]
class AnnConfiguredCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

@[ADI::Register]
@[ACONA::AsCommand("|empty-name")]
class EmptyCommandName < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

describe ATH do
  describe "Console", tags: "compiled" do
    it "errors if no name is provided" do
      assert_error "Console command 'TestCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        @[ACONA::AsCommand]
        class TestCommand < ACON::Command
        end
      CR
    end
  end

  # Fetching the console application initializes everything.
  # Kinda hacky, but do this in a `before_all` to assert they both start off un-initialized.
  before_all do
    EagerlyInitializedCommand.initialized.should be_false
    LazyInitializedCommand.initialized.should be_false
  end

  it "is initialized eagerly if not configured via annotation" do
    application = ADI.container.athena_console_application
    EagerlyInitializedCommand.initialized.should be_true
    application.has?("eagerly-initialized").should be_true
    EagerlyInitializedCommand.initialized.should be_true
  end

  it "is initialized lazily if configured via annotation" do
    application = ADI.container.athena_console_application
    LazyInitializedCommand.initialized.should be_false
    application.has?("lazy-initialized").should be_true
    LazyInitializedCommand.initialized.should be_false # Lazy command wrapper
    application.get("lazy-initialized").help.should be_empty
    LazyInitializedCommand.initialized.should be_true
  end

  it "applies data from annotation" do
    application = ADI.container.athena_console_application
    application.has?("tset").should be_true

    command = application.get "annn"
    command.hidden?.should be_true
    command.description.should eq "Test desc"
    command.aliases.should eq ["tset"]
  end

  it "applies hidden status via empty command name" do
    application = ADI.container.athena_console_application
    command = application.get "empty-name"
    command.name.should eq "empty-name"
    command.hidden?.should be_true
    command.aliases.should be_empty
  end
end
