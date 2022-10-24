require "../spec_helper"

@[ACONA::AsCommand("blahhhh")]
private class MockCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

describe ACON::Commands::Lazy do
  it "applies metadata to the instantiated command" do
    lazy_command = ACON::Commands::Lazy.new "cmd_name", ["foo", "bar"], "description", true, ->{ MockCommand.new.as ACON::Command }
    command = lazy_command.command

    command.should be_a MockCommand
    command.name.should eq "cmd_name"
    command.aliases.should eq ["foo", "bar"]
    command.description.should eq "description"
    command.hidden?.should be_true
  end

  it "forwards methods to the wrapped command instance" do
    mock_command = MockCommand.new

    lazy_command = ACON::Commands::Lazy.new "cmd_name", ["foo", "bar"], "description", true, ->{ mock_command.as ACON::Command }
    command = lazy_command.command

    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new
    command.process_title "title"
    command.usage "usages"
    command.argument "name"
    command.option "active"

    command.definition.should eq mock_command.definition
    command.help.should eq mock_command.help
    command.processed_help.should eq mock_command.processed_help
    command.synopsis.should eq mock_command.synopsis
    command.usages.should eq mock_command.usages
    command.helper(ACON::Helper::Question).should eq mock_command.helper(ACON::Helper::Question)
  end

  it "is runnable" do
    command = MockCommand.new
    command.application = ACON::Application.new "foo"

    tester = ACON::Spec::CommandTester.new command
    tester.execute.should eq ACON::Command::Status::SUCCESS
  end
end
