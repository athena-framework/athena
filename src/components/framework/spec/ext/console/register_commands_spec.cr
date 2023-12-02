require "../../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line, codegen: true
    require "../../spec_helper.cr"

    #{code}
  CR
end

private def assert_success(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_success <<-CR, line: line, codegen: true
    require "../../spec_helper.cr"

    #{code}
  CR
end

describe ATH do
  describe "Console", tags: "compiler" do
    it "errors if no name is provided" do
      assert_error "Console command 'TestCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        @[ACONA::AsCommand]
        class TestCommand < ACON::Command
        end
      CR
    end

    it "is initialized eagerly if not configured via annotation" do
      assert_success <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        class TestCommand < ACON::Command
          class_getter initialized = false

          def initialize
            @@initialized = true
            super
          end

          protected def configure : Nil
            self
              .name("test")
          end

          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        it do
          TestCommand.initialized.should be_false
          application = ADI.container.athena_console_application
          TestCommand.initialized.should be_true
          application.has?("test").should be_true
          TestCommand.initialized.should be_true
        end
      CR
    end

    it "is initialized lazily if configured via annotation" do
      assert_success <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        @[ACONA::AsCommand("test")]
        class TestCommand < ACON::Command
          class_getter initialized = false

          def initialize
            @@initialized = true
            super
          end

          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        it do
          TestCommand.initialized.should be_false
          application = ADI.container.athena_console_application
          TestCommand.initialized.should be_false
          application.has?("test").should be_true
          TestCommand.initialized.should be_false # Lazy command wrapper
          application.get("test").help.should be_empty
          TestCommand.initialized.should be_true
        end
      CR
    end

    it "applies data from annotation" do
      assert_success <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        @[ACONA::AsCommand("test|tset", hidden: true, description: "Test desc")]
        class TestCommand < ACON::Command
          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        it do
          application = ADI.container.athena_console_application
          application.has?("tset").should be_true

          command = application.get "test"
          command.hidden?.should be_true
          command.description.should eq "Test desc"
          command.aliases.should eq ["tset"]
        end
      CR
    end

    it "applies hidden status via empty command name" do
      assert_success <<-CR
        require "../../spec_helper.cr"

        @[ADI::Register]
        @[ACONA::AsCommand("|test")]
        class TestCommand < ACON::Command
          protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
            ACON::Command::Status::SUCCESS
          end
        end

        it do
          application = ADI.container.athena_console_application
          command = application.get "test"
          command.name.should eq "test"
          command.hidden?.should be_true
          command.aliases.should be_empty
        end
      CR
    end
  end
end
