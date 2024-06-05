require "../spec_helper"

private def normalize(input : String) : String
  input.gsub EOL, "\n"
end

struct ListCommandTest < ASPEC::TestCase
  def test_execute_lists_commands : Nil
    app = ACON::Application.new "foo"
    tester = ACON::Spec::CommandTester.new app.get("list")
    tester.execute command: "list", decorated: false

    tester.display.should match /help\s{2,}Display help for a command/
  end

  def test_with_raw_option : Nil
    app = ACON::Application.new "foo"
    tester = ACON::Spec::CommandTester.new app.get("list")
    tester.execute command: "list", "--raw": true

    tester.display.should eq "completion   Dump the shell completion script\nhelp         Display help for a command\nlist         List available commands\n"
  end

  def test_with_namespace_argument : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new

    tester = ACON::Spec::CommandTester.new app.get("list")
    tester.execute command: "list", namespace: "foo", "--raw": true

    tester.display.should eq "foo:bar   The foo:bar command\n"
  end

  def test_lists_command_in_expected_order : Nil
    app = ACON::Application.new "foo"
    app.add Foo6Command.new

    tester = ACON::Spec::CommandTester.new app.get("list")
    tester.execute command: "list", decorated: false

    tester.display(true).should eq normalize <<-OUTPUT
      foo UNKNOWN

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
        completion  Dump the shell completion script
        help        Display help for a command
        list        List available commands
       0foo
        0foo:bar    0foo:bar command\n
      OUTPUT
  end

  def test_lists_commands_in_expected_order_in_raw_mode : Nil
    app = ACON::Application.new "foo"
    app.add Foo6Command.new

    tester = ACON::Spec::CommandTester.new app.get("list")
    tester.execute command: "list", "--raw": true

    tester.display.should eq "completion   Dump the shell completion script\nhelp         Display help for a command\nlist         List available commands\n0foo:bar     0foo:bar command\n"
  end

  @[DataProvider("complete_provider")]
  def test_complete(input : Array(String), expected_suggestions : Array(String)) : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new

    tester = ACON::Spec::CommandCompletionTester.new app.get "list"
    suggestions = tester.complete input

    suggestions.should eq expected_suggestions
  end

  def complete_provider : Hash
    {
      "--format option"   => {["--format"], ["txt"]},
      "empty namespace"   => {[] of String, ["_global", "foo"]},
      "partial namespace" => {["f"], ["_global", "foo"]},
    }
  end
end
