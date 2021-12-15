require "../spec_helper"

describe ACON::Commands::Help do
  describe "#execute" do
    it "with command alias" do
      command = ACON::Commands::Help.new
      command.application = ACON::Application.new "foo"

      tester = ACON::Spec::CommandTester.new command
      tester.execute command_name: "li", decorated: false

      tester.display.should contain "list [options] [--] [<namespace>]"
      tester.display.should contain "format=FORMAT"
      tester.display.should contain "raw"
    end

    it "executes" do
      command = ACON::Commands::Help.new

      tester = ACON::Spec::CommandTester.new command
      command.command = ACON::Commands::List.new

      tester.execute decorated: false

      tester.display.should contain "list [options] [--] [<namespace>]"
      tester.display.should contain "format=FORMAT"
      tester.display.should contain "raw"
    end

    it "with application command" do
      app = ACON::Application.new "foo"
      tester = ACON::Spec::CommandTester.new app.get "help"
      tester.execute command_name: "list"

      tester.display.should contain "list [options] [--] [<namespace>]"
      tester.display.should contain "format=FORMAT"
      tester.display.should contain "raw"
    end
  end
end
