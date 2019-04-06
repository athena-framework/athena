require "./cli_spec_helper"

command_list = <<-LIST
Registered Commands:
\taa
\t\taa:array - Array of bools
\tparams
\t\tparams:default - Required param with a default value
\t\tparams:multi - Has multiple required params
\t\tparams:optional - optional string
\tungrouped
\t\tto_s - Command to test .to_s on
\t\tuser - Creates a user with the given id\n
LIST

describe Athena::Cli::Registry do
  describe ".find" do
    describe "for valid commands" do
      it "should be able to find by name" do
        command = Athena::Cli::Registry.commands.find { |c| c.name == "user" }
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

  describe ".to_s" do
    it "should list the commands" do
      Athena::Cli::Registry.to_s.should eq command_list
    end
  end
end
