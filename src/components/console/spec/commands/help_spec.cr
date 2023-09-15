require "../spec_helper"

struct HelpCommandTest < ASPEC::TestCase
  def test_execute_alias : Nil
    command = ACON::Commands::Help.new
    command.application = ACON::Application.new "foo"

    tester = ACON::Spec::CommandTester.new command
    tester.execute command_name: "li", decorated: false

    tester.display.should contain "list [options] [--] [<namespace>]"
    tester.display.should contain "format=FORMAT"
    tester.display.should contain "raw"
  end

  def test_execute : Nil
    command = ACON::Commands::Help.new
    command.application = ACON::Application.new "foo"

    tester = ACON::Spec::CommandTester.new command
    tester.execute command_name: "li", decorated: false

    tester.display.should contain "list [options] [--] [<namespace>]"
    tester.display.should contain "format=FORMAT"
    tester.display.should contain "raw"
  end

  def test_execute_application_command : Nil
    app = ACON::Application.new "foo"
    tester = ACON::Spec::CommandTester.new app.get "help"
    tester.execute command_name: "list"

    tester.display.should contain "list [options] [--] [<namespace>]"
    tester.display.should contain "format=FORMAT"
    tester.display.should contain "raw"
  end

  @[DataProvider("complete_provider")]
  def test_complete(input : Array(String), expected_suggestions : Array(String)) : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new

    tester = ACON::Spec::CommandCompletionTester.new app.get "help"
    suggestions = tester.complete input

    suggestions.should eq expected_suggestions
  end

  def complete_provider : Hash
    {
      "long option"  => {["--format"], ["txt"]},
      "nothing"      => {[] of String, ["completion", "help", "list", "foo:bar"]},
      "command name" => {["f"], ["completion", "help", "list", "foo:bar"]},
    }
  end
end
