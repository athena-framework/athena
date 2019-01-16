require "./cli_spec_helper"

describe Athena::Cli::Registry do
  describe "for valid commands" do
    it "should be able to find by name" do
      command = Athena::Cli::Registry.commands.find { |c| c.command_name == "user" }
      command.should_not be_nil
      command.not_nil!.description.should eq "Creates a user with the given id"
    end
  end

  describe "for an unregistered command" do
    it "should raise" do
      expect_raises Exception, "No command with the name 'foobar' has been registered" { Athena::Cli::Registry.find "foobar" }
    end
  end
end
