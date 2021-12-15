require "../spec_helper"

describe ACON::Commands::List do
  describe "#execute" do
    it "executes" do
      app = ACON::Application.new "foo"
      tester = ACON::Spec::CommandTester.new app.get("list")
      tester.execute command: "list", decorated: false

      tester.display.should match /help\s{2,}Display help for a command/
    end

    it "with raw option" do
      app = ACON::Application.new "foo"
      tester = ACON::Spec::CommandTester.new app.get("list")
      tester.execute command: "list", "--raw": true

      tester.display.should eq "help   Display help for a command\nlist   List commands\n"
    end

    it "with namespace argument" do
      app = ACON::Application.new "foo"
      app.add FooCommand.new

      tester = ACON::Spec::CommandTester.new app.get("list")
      tester.execute command: "list", namespace: "foo", "--raw": true

      tester.display.should eq "foo:bar   The foo:bar command\n"
    end

    it "lists commands order" do
      app = ACON::Application.new "foo"
      app.add Foo6Command.new

      tester = ACON::Spec::CommandTester.new app.get("list")
      tester.execute command: "list", decorated: false

      tester.display.should eq <<-OUTPUT
      foo 0.1.0

      Usage:
        command [options] [arguments]

      Options:
        -h, --help            Display help for the given command. When no command is given display help for the list command
        -q, --quiet           Do not output any message
        -V, --version         Display this application version
            --ansi|--no-ansi  Force (or disable --no-ansi) ANSI output
        -n, --no-interaction  Do not ask any interactive question
        -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

      Available commands:
        help      Display help for a command
        list      List commands
       0foo
        0foo:bar  0foo:bar command\n
      OUTPUT
    end

    it "lists commands order with raw option" do
      app = ACON::Application.new "foo"
      app.add Foo6Command.new

      tester = ACON::Spec::CommandTester.new app.get("list")
      tester.execute command: "list", "--raw": true

      tester.display.should eq "help       Display help for a command\nlist       List commands\n0foo:bar   0foo:bar command\n"
    end
  end
end
