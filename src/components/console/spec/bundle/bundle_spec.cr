require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: %(require "./spec_helper.cr")
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: %(require "./spec_helper.cr")
end

@[ADI::Register]
class EagerlyInitializedCommand < ACON::Command
  class_getter? initialized = false

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
  class_getter? initialized = false

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

private class CustomApplication < ACON::Application
  def initialize(name : String, version : String)
    super name, version, ADI.container
  end
end

describe ACON::Bundle do
  describe "compiler", tags: "compiled" do
    it "tags commands and provides them to the command loader" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        @[ACONA::AsCommand("lazy")]
        class LazyCommand < ACON::Command
          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        @[ADI::Register]
        class EagerCommand < ACON::Command
          protected def configure : Nil
            self.name "eager"
          end

          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              loader = sh["console_command_loader"]
            %}
            ASPEC.compile_time_assert(\{{ sh["lazy_command"]["tags"]["console.command"] != nil }}, "Expected commands to be tagged 'console.command'")
            ASPEC.compile_time_assert(\{{ loader["public"] }}, "Expected the command loader to be public")
            ASPEC.compile_time_assert(\{{ loader["parameters"]["command_map"]["value"].stringify.includes?(%("lazy" => LazyCommand)) }}, "Expected the lazy command to be in the command map")
            ASPEC.compile_time_assert(\{{ loader["parameters"]["eager_commands"]["value"].stringify == "[_eager_command_public] of ACON::Command" }}, "Expected the eager command to be provided to the command loader")
          end
        end
      CR
    end

    it "errors if no name is provided" do
      assert_compile_time_error "Console command 'TestCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
        @[ADI::Register]
        @[ACONA::AsCommand]
        class TestCommand < ACON::Command
        end
      CR
    end
  end

  # Creating the application initializes everything.
  # Kinda hacky, but do this in a `before_all` to assert they both start off un-initialized.
  before_all do
    EagerlyInitializedCommand.initialized?.should be_false
    LazyInitializedCommand.initialized?.should be_false
  end

  it "uses the provided name and version" do
    application = ACON::Application.new "My App", "1.2.3", ADI.container
    application.name.should eq "My App"
    application.version.should eq "1.2.3"
  end

  it "can be passed the container from a subclass's constructor" do
    application = CustomApplication.new "Custom", "2.0.0"
    application.name.should eq "Custom"
    application.has?("lazy-initialized").should be_true
  end

  it "is initialized eagerly if not configured via annotation" do
    application = ACON::Application.new "Test", "1.0.0", ADI.container
    EagerlyInitializedCommand.initialized?.should be_true
    application.has?("eagerly-initialized").should be_true
    EagerlyInitializedCommand.initialized?.should be_true
  end

  it "is initialized lazily if configured via annotation" do
    application = ACON::Application.new "Test", "1.0.0", ADI.container
    LazyInitializedCommand.initialized?.should be_false
    application.has?("lazy-initialized").should be_true
    LazyInitializedCommand.initialized?.should be_false # Lazy command wrapper
    application.get("lazy-initialized").help.should be_empty
    LazyInitializedCommand.initialized?.should be_true
  end

  it "applies data from annotation" do
    application = ACON::Application.new "Test", "1.0.0", ADI.container
    application.has?("tset").should be_true

    command = application.get "annn"
    command.hidden?.should be_true
    command.description.should eq "Test desc"
    command.aliases.should eq ["tset"]
  end

  it "applies hidden status via empty command name" do
    application = ACON::Application.new "Test", "1.0.0", ADI.container
    command = application.get "empty-name"
    command.name.should eq "empty-name"
    command.hidden?.should be_true
    command.aliases.should be_empty
  end

  it "lists the lazy commands" do
    application = ACON::Application.new "Test", "1.0.0", ADI.container
    application.commands.keys.should contain "lazy-initialized"
  end

  it "raises if a lazy command does not exist" do
    expect_raises ACON::Exception::CommandNotFound, "Command 'missing' does not exist." do
      ADI.container.console_command_loader.get "missing"
    end
  end
end
