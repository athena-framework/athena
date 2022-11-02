require "../../spec_helper"

describe ATH do
  describe "Console", focus: true do
    it "errors if no name is provided" do
      ASPEC::Methods.assert_error "Console command 'TestCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
        require "../../spec_helper.cr"
        
        @[ADI::Register]
        @[ACONA::AsCommand]
        class TestCommand < ACON::Command
        end
      CR
    end

    it "is initialized eagerly if not configured via annotation" do
      ASPEC::Methods.assert_success <<-CR
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

        TestCommand.initialized.should be_false
        application = ADI.container.athena_console_application
        TestCommand.initialized.should be_true
        application.has?("test").should be_true
        TestCommand.initialized.should be_true
      CR
    end

    it "is initialized lazily if configured via annotation" do
      ASPEC::Methods.assert_success <<-CR
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

        raise "oh no"

        TestCommand.initialized.should be_false
        application = ADI.container.athena_console_application
        TestCommand.initialized.should be_false
        application.has?("test").should be_false
        TestCommand.initialized.should be_false
      CR
    end
  end
end
