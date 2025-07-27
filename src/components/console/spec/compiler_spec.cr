require "./spec_helper"

describe Athena::Console do
  describe "compiler errors", tags: "compiled" do
    describe "when a command configured via annotation doesn't have a name" do
      it "non hidden no aliases" do
        ASPEC::Methods.assert_compile_time_error "Console command 'NoNameCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
          require "./spec_helper.cr"

          @[ACONA::AsCommand]
          class NoNameCommand < ACON::Command
            protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
              ACON::Command::Status::SUCCESS
            end
          end

          NoNameCommand.default_name
        CR
      end

      it "hidden" do
        ASPEC::Methods.assert_compile_time_error "Console command 'NoNameCommand' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
          require "./spec_helper.cr"

          @[ACONA::AsCommand(hidden: true)]
          class NoNameCommand < ACON::Command
            protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
              ACON::Command::Status::SUCCESS
            end
          end

          NoNameCommand.default_name
        CR
      end
    end
  end
end
