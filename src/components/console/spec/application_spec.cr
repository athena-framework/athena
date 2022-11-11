require "./spec_helper"

struct ApplicationTest < ASPEC::TestCase
  @col_size : Int32?

  def initialize
    @col_size = ENV["COLUMNS"]?.try &.to_i
  end

  def tear_down : Nil
    if size = @col_size
      ENV["COLUMNS"] = size.to_s
    else
      ENV.delete "COLUMNS"
    end

    ENV.delete "SHELL_VERBOSITY"
  end

  protected def assert_file_equals_string(filepath : String, string : String, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    normalized_path = File.join __DIR__, "fixtures", filepath
    string.should match(Regex.new(File.read(normalized_path))), file: file, line: line
  end

  protected def ensure_static_command_help(application : ACON::Application) : Nil
    application.each_command do |command|
      command.help = command.help.gsub("%command.full_name%", "console %command.name%")
    end
  end

  def test_long_version : Nil
    ACON::Application.new("foo", "1.2.3").long_version.should eq "foo <info>1.2.3</info>"
  end

  def test_help : Nil
    ACON::Application.new("foo", "1.2.3").help.should eq "foo <info>1.2.3</info>"
  end

  def test_commands : Nil
    app = ACON::Application.new "foo"
    commands = app.commands

    commands["help"].should be_a ACON::Commands::Help
    commands["list"].should be_a ACON::Commands::List

    app.add FooCommand.new
    commands = app.commands "foo"
    commands.size.should eq 1
  end

  def test_commands_with_loader : Nil
    app = ACON::Application.new "foo"
    commands = app.commands

    commands["help"].should be_a ACON::Commands::Help
    commands["list"].should be_a ACON::Commands::List

    app.add FooCommand.new
    commands = app.commands "foo"
    commands.size.should eq 1

    app.command_loader = ACON::Loader::Factory.new({
      "foo:bar1" => ->{ Foo1Command.new.as ACON::Command },
    })
    commands = app.commands "foo"
    commands.size.should eq 2
    commands["foo:bar"].should be_a FooCommand
    commands["foo:bar1"].should be_a Foo1Command
  end

  def test_add : Nil
    app = ACON::Application.new "foo"
    app.add foo = FooCommand.new
    commands = app.commands

    commands["foo:bar"].should be foo

    # TODO: Add a splat/enumerable overload of #add ?
  end

  def test_has_get : Nil
    app = ACON::Application.new "foo"
    app.has?("list").should be_true
    app.has?("afoobar").should be_false

    app.add foo = FooCommand.new
    app.has?("afoobar").should be_true
    app.get("afoobar").should be foo
    app.get("foo:bar").should be foo

    app = ACON::Application.new "foo"
    app.add FooCommand.new

    pointerof(app.@wants_help).value = true

    app.get("foo:bar").should be_a ACON::Commands::Help
  end

  def test_has_get_with_loader : Nil
    app = ACON::Application.new "foo"
    app.has?("list").should be_true
    app.has?("afoobar").should be_false

    app.add foo = FooCommand.new
    app.has?("afoobar").should be_true
    app.get("foo:bar").should be foo
    app.get("afoobar").should be foo

    app.command_loader = ACON::Loader::Factory.new({
      "foo:bar1" => ->{ Foo1Command.new.as ACON::Command },
    })

    app.has?("afoobar").should be_true
    app.get("foo:bar").should be foo
    app.get("afoobar").should be foo
    app.has?("foo:bar1").should be_true
    (foo1 = app.get("foo:bar1")).should be_a Foo1Command
    app.has?("afoobar1").should be_true
    app.get("afoobar1").should be foo1
  end

  def test_silent_help : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    tester = ACON::Spec::ApplicationTester.new app

    tester.run("-h": true, "-q": true, decorated: false)
    tester.display.should be_empty
  end

  def test_get_missing_command : Nil
    app = ACON::Application.new "foo"

    expect_raises ACON::Exceptions::CommandNotFound, "The command 'foofoo' does not exist." do
      app.get "foofoo"
    end
  end

  def test_namespaces : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.namespaces.should eq ["foo"]
  end

  def test_find_namespace : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.find_namespace("foo").should eq "foo"
    app.find_namespace("f").should eq "foo"
    app.add Foo1Command.new
    app.find_namespace("foo").should eq "foo"
  end

  def test_find_namespace_subnamespaces : Nil
    app = ACON::Application.new "foo"
    app.add FooSubnamespaced1Command.new
    app.add FooSubnamespaced2Command.new
    app.find_namespace("foo").should eq "foo"
  end

  def test_find_namespace_ambiguous : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add BarBucCommand.new
    app.add Foo2Command.new

    expect_raises ACON::Exceptions::NamespaceNotFound, "The namespace 'f' is ambiguous." do
      app.find_namespace "f"
    end
  end

  def test_find_namespace_invalid : Nil
    app = ACON::Application.new "foo"

    expect_raises ACON::Exceptions::NamespaceNotFound, "There are no commands defined in the 'bar' namespace." do
      app.find_namespace "bar"
    end
  end

  def test_find_namespace_does_not_fail_on_deep_similar_namespaces : Nil
    app = ACON::Application.new "foo"

    app.register "foo:sublong:bar" { ACON::Command::Status::SUCCESS }
    app.register "bar:sub:foo" { ACON::Command::Status::SUCCESS }

    app.find_namespace("f:sub").should eq "foo:sublong"
  end

  def test_find : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new

    app.find("foo:bar").should be_a FooCommand
    app.find("h").should be_a ACON::Commands::Help
    app.find("f:bar").should be_a FooCommand
    app.find("f:b").should be_a FooCommand
    app.find("a").should be_a FooCommand
  end

  def test_find_non_ambiguous : Nil
    app = ACON::Application.new "foo"
    app.add TestAmbiguousCommandRegistering.new
    app.add TestAmbiguousCommandRegistering2.new

    app.find("test").name.should eq "test-ambiguous"
  end

  def test_find_unique_name_but_namespace_name : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new

    expect_raises ACON::Exceptions::CommandNotFound, "Command 'foo1' is not defined." do
      app.find "foo1"
    end
  end

  def test_find_case_sensitive_first : Nil
    app = ACON::Application.new "foo"
    app.add FooSameCaseUppercaseCommand.new
    app.add FooSameCaseLowercaseCommand.new

    app.find("f:B").should be_a FooSameCaseUppercaseCommand
    app.find("f:BAR").should be_a FooSameCaseUppercaseCommand
    app.find("f:b").should be_a FooSameCaseLowercaseCommand
    app.find("f:bar").should be_a FooSameCaseLowercaseCommand
  end

  def test_find_case_insensitive_fallback : Nil
    app = ACON::Application.new "foo"
    app.add FooSameCaseLowercaseCommand.new

    app.find("f:b").should be_a FooSameCaseLowercaseCommand
    app.find("f:B").should be_a FooSameCaseLowercaseCommand
    app.find("fOO:bar").should be_a FooSameCaseLowercaseCommand
  end

  def test_find_case_insensitive_ambiguous : Nil
    app = ACON::Application.new "foo"
    app.add FooSameCaseUppercaseCommand.new
    app.add FooSameCaseLowercaseCommand.new

    expect_raises ACON::Exceptions::CommandNotFound, "Command 'FOO:bar' is ambiguous." do
      app.find "FOO:bar"
    end
  end

  def test_find_command_loader : Nil
    app = ACON::Application.new "foo"

    app.command_loader = ACON::Loader::Factory.new({
      "foo:bar" => ->{ FooCommand.new.as ACON::Command },
    })

    app.find("foo:bar").should be_a FooCommand
    app.find("h").should be_a ACON::Commands::Help
    app.find("f:bar").should be_a FooCommand
    app.find("f:b").should be_a FooCommand
    app.find("a").should be_a FooCommand
  end

  @[DataProvider("ambiguous_abbreviations_provider")]
  def test_find_ambiguous_abbreviations(abbreviation, expected_message) : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new

    expect_raises ACON::Exceptions::CommandNotFound, expected_message do
      app.find abbreviation
    end
  end

  def ambiguous_abbreviations_provider : Tuple
    {
      {"f", "Command 'f' is not defined."},
      {"a", "Command 'a' is ambiguous."},
      {"foo:b", "Command 'foo:b' is ambiguous."},
    }
  end

  def test_find_ambiguous_abbreviations_finds_command_if_alternatives_are_hidden : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add FooHiddenCommand.new

    app.find("foo:").should be_a FooCommand
  end

  def test_find_command_equal_namespace
    app = ACON::Application.new "foo"
    app.add Foo3Command.new
    app.add Foo4Command.new

    app.find("foo3:bar").should be_a Foo3Command
    app.find("foo3:bar:toh").should be_a Foo4Command
  end

  def test_find_ambiguous_namespace_but_unique_name
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add FooBarCommand.new

    app.find("f:f").should be_a FooBarCommand
  end

  def test_find_missing_namespace
    app = ACON::Application.new "foo"
    app.add Foo4Command.new

    app.find("f::t").should be_a Foo4Command
  end

  @[DataProvider("invalid_command_names_single_provider")]
  def test_find_alternative_exception_message_single(name) : Nil
    app = ACON::Application.new "foo"
    app.add Foo3Command.new

    expect_raises ACON::Exceptions::CommandNotFound, "Did you mean this?" do
      app.find name
    end
  end

  def invalid_command_names_single_provider : Tuple
    {
      {"foo3:barr"},
      {"fooo3:bar"},
    }
  end

  def test_doesnt_run_alternative_namespace_name : Nil
    app = ACON::Application.new "foo"
    app.add Foo1Command.new
    app.auto_exit = false

    tester = ACON::Spec::ApplicationTester.new app
    tester.run command: "foos:bar1", decorated: false
    self.assert_file_equals_string "text/application_alternative_namespace.txt", tester.display
  end

  def test_run_alternate_command_name : Nil
    app = ACON::Application.new "foo"
    app.add FooWithoutAliasCommand.new
    app.auto_exit = false
    tester = ACON::Spec::ApplicationTester.new app

    tester.inputs = ["y"]
    tester.run command: "foos", decorated: false
    output = tester.display.strip
    output.should contain "Command 'foos' is not defined"
    output.should contain "Do you want to run 'foo' instead? (yes/no) [no]:"
    output.should contain "execute called"
  end

  def test_dont_run_alternate_command_name : Nil
    app = ACON::Application.new "foo"
    app.add FooWithoutAliasCommand.new
    app.auto_exit = false
    tester = ACON::Spec::ApplicationTester.new app

    tester.inputs = ["n"]
    tester.run(command: "foos", decorated: false).should eq ACON::Command::Status::FAILURE
    output = tester.display.strip
    output.should contain "Command 'foos' is not defined"
    output.should contain "Do you want to run 'foo' instead? (yes/no) [no]:"
  end

  def test_find_alternative_exception_message_multiple : Nil
    ENV["COLUMNS"] = "120"
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new

    # Command + plural
    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "foo:BAR"
    end

    message = ex.message.should_not be_nil
    message.should contain "Did you mean one of these?"
    message.should contain "foo1:bar"
    message.should contain "foo:bar"

    # Namespace + plural
    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "foo2:bar"
    end

    message = ex.message.should_not be_nil
    message.should contain "Did you mean one of these?"
    message.should contain "foo1"

    app.add Foo3Command.new
    app.add Foo4Command.new

    # Subnamespace + plural
    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "foo3:"
    end

    message = ex.message.should_not be_nil
    message.should contain "foo3:bar"
    message.should contain "foo3:bar:toh"
  end

  def test_find_alternative_commands : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new

    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "Unknown command"
    end

    ex.alternatives.should be_empty
    ex.message.should eq "Command 'Unknown command' is not defined."

    # Test if "bar1" command throw a "CommandNotFoundException" and does not contain
    # "foo:bar" as alternative because "bar1" is too far from "foo:bar"
    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "bar1"
    end

    ex.alternatives.should eq ["afoobar1", "foo:bar1"]

    message = ex.message.should_not be_nil
    message.should contain "Command 'bar1' is not defined"
    message.should contain "afoobar1"
    message.should contain "foo:bar1"
    message.should_not match /foo:bar(?!1)/
  end

  def test_find_alternative_commands_with_alias : Nil
    foo_command = FooCommand.new
    foo_command.aliases = ["foo2"]

    app = ACON::Application.new "foo"
    app.command_loader = ACON::Loader::Factory.new({
      "foo3" => ->{ foo_command.as ACON::Command },
    })
    app.add foo_command

    app.find("foo").should be foo_command
  end

  def test_find_alternate_namespace : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new
    app.add Foo3Command.new

    ex = expect_raises ACON::Exceptions::CommandNotFound, "There are no commands defined in the 'Unknown-namespace' namespace." do
      app.find "Unknown-namespace:Unknown-command"
    end
    ex.alternatives.should be_empty

    ex = expect_raises ACON::Exceptions::CommandNotFound do
      app.find "foo2:command"
    end
    ex.alternatives.should eq ["foo", "foo1", "foo3"]

    message = ex.message.should_not be_nil
    message.should contain "There are no commands defined in the 'foo2' namespace."
    message.should contain "foo"
    message.should contain "foo1"
    message.should contain "foo3"
  end

  def test_find_alternates_output : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo1Command.new
    app.add Foo2Command.new
    app.add Foo3Command.new
    app.add FooHiddenCommand.new

    expect_raises ACON::Exceptions::CommandNotFound, "There are no commands defined in the 'Unknown-namespace' namespace." do
      app.find "Unknown-namespace:Unknown-command"
    end.alternatives.should be_empty

    expect_raises ACON::Exceptions::CommandNotFound, /Command 'foo' is not defined\..*Did you mean one of these\?.*/m do
      app.find "foo"
    end.alternatives.should eq ["afoobar", "afoobar1", "afoobar2", "foo1:bar", "foo3:bar", "foo:bar", "foo:bar1"]
  end

  def test_find_double_colon_doesnt_find_command : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add Foo4Command.new

    expect_raises ACON::Exceptions::CommandNotFound, "Command 'foo::bar' is not defined." do
      app.find "foo::bar"
    end
  end

  def test_find_hidden_command_exact_name : Nil
    app = ACON::Application.new "foo"
    app.add FooHiddenCommand.new

    app.find("foo:hidden").should be_a FooHiddenCommand
    app.find("afoohidden").should be_a FooHiddenCommand
  end

  def test_find_ambiguous_commands_if_all_alternatives_are_hidden : Nil
    app = ACON::Application.new "foo"
    app.add FooCommand.new
    app.add FooHiddenCommand.new

    app.find("foo:").should be_a FooCommand
  end

  def test_set_catch_exceptions : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "120"
    tester = ACON::Spec::ApplicationTester.new app

    app.catch_exceptions = true
    tester.run command: "foo", decorated: false
    self.assert_file_equals_string "text/application_renderexception1.txt", tester.display

    tester.run command: "foo", decorated: false, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception1.txt", tester.error_output
    tester.display.should be_empty

    app.catch_exceptions = false

    expect_raises Exception, "Command 'foo' is not defined." do
      tester.run command: "foo", decorated: false
    end
  end

  def test_render_exception : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "120"
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo", decorated: false, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception1.txt", tester.error_output

    tester.run command: "foo", decorated: false, capture_stderr_separately: true, verbosity: :verbose
    tester.error_output.should contain "Exception trace"

    tester.run command: "list", "--foo": true, decorated: false, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception2.txt", tester.error_output

    app.add Foo3Command.new
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo3:bar", decorated: false, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception3.txt", tester.error_output

    tester.run({"command" => "foo3:bar"}, decorated: false, verbosity: :verbose)
    tester.display.should match /\[Exception\]\s*First exception/
    tester.display.should match /\[Exception\]\s*Second exception/
    tester.display.should match /\[Exception\]\s*Third exception/

    tester.run command: "foo3:bar", decorated: true
    self.assert_file_equals_string "text/application_renderexception3_decorated.txt", tester.display

    tester.run command: "foo3:bar", decorated: true, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception3_decorated.txt", tester.error_output

    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "32"
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo", decorated: false, capture_stderr_separately: true
    self.assert_file_equals_string "text/application_renderexception4.txt", tester.error_output

    ENV["COLUMNS"] = "120"
  end

  def ptest_render_exception_double_width_characters : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "120"
    tester = ACON::Spec::ApplicationTester.new app

    app.register "foo" do
      raise "エラーメッセージ"
    end

    tester.run command: "foo", decorated: false, capture_stderr_separately: true
    tester.error_output.should eq RENDER_EXCEPTION_DOUBLE_WIDTH
  end

  def test_render_exception_escapes_lines : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "22"
    app.register "foo" do
      raise "dont break here <info>!</info>"
    end
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo", decorated: false
    self.assert_file_equals_string "text/application_renderexception_escapeslines.txt", tester.display

    ENV["COLUMNS"] = "120"
  end

  def test_render_exception_line_breaks : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    ENV["COLUMNS"] = "120"
    app.register "foo" do
      raise "\n\nline 1 with extra spaces        \nline 2\n\nline 4\n"
    end
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo", decorated: false
    self.assert_file_equals_string "text/application_renderexception_linebreaks.txt", tester.display
  end

  def test_render_exception_escapes_lines_of_synopsis : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false

    app.register "foo" do
      raise "some exception"
    end.argument "info"

    tester = ACON::Spec::ApplicationTester.new app
    tester.run command: "foo", decorated: false
    self.assert_file_equals_string "text/application_renderexception_synopsis_escapeslines.txt", tester.display
  end

  def test_run_passes_io_thru : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    app.add command = Foo1Command.new

    input = ACON::Input::Hash.new({"command" => "foo:bar1"})
    output = ACON::Output::IO.new IO::Memory.new

    app.run input, output

    command.input.should eq input
    command.output.should eq output
  end

  def test_run_default_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    self.ensure_static_command_help app
    tester = ACON::Spec::ApplicationTester.new app

    tester.run decorated: false
    self.assert_file_equals_string "text/application_run1.txt", tester.display
  end

  def test_run_help_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    self.ensure_static_command_help app
    tester = ACON::Spec::ApplicationTester.new app

    tester.run "--help": true, decorated: false
    self.assert_file_equals_string "text/application_run2.txt", tester.display

    tester.run "-h": true, decorated: false
    self.assert_file_equals_string "text/application_run2.txt", tester.display
  end

  def test_run_help_list_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    self.ensure_static_command_help app
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "list", "--help": true, decorated: false
    self.assert_file_equals_string "text/application_run3.txt", tester.display

    tester.run command: "list", "-h": true, decorated: false
    self.assert_file_equals_string "text/application_run3.txt", tester.display
  end

  def test_run_ansi : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    tester = ACON::Spec::ApplicationTester.new app

    tester.run "--ansi": true
    tester.output.decorated?.should be_true

    tester.run "--no-ansi": true
    tester.output.decorated?.should be_false
  end

  def test_run_version : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    tester = ACON::Spec::ApplicationTester.new app

    tester.run "--version": true, decorated: false
    self.assert_file_equals_string "text/application_run4.txt", tester.display

    tester.run "-V": true, decorated: false
    self.assert_file_equals_string "text/application_run4.txt", tester.display
  end

  def test_run_quest : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "list", "--quiet": true, decorated: false
    tester.display.should be_empty
    tester.input.interactive?.should be_false

    tester.run command: "list", "-q": true, decorated: false
    tester.display.should be_empty
    tester.input.interactive?.should be_false
  end

  def test_run_verbosity : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    self.ensure_static_command_help app
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "list", "--verbose": true, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERBOSE

    tester.run command: "list", "--verbose": 1, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERBOSE

    tester.run command: "list", "--verbose": 2, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERY_VERBOSE

    tester.run command: "list", "--verbose": 3, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::DEBUG

    tester.run command: "list", "--verbose": 4, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERBOSE

    tester.run command: "list", "-v": true, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERBOSE

    tester.run command: "list", "-vv": true, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::VERY_VERBOSE

    tester.run command: "list", "-vvv": true, decorated: false
    tester.output.verbosity.should eq ACON::Output::Verbosity::DEBUG
  end

  def test_run_help_help_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    self.ensure_static_command_help app
    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "help", "--help": true, decorated: false
    self.assert_file_equals_string "text/application_run5.txt", tester.display

    tester.run command: "help", "-h": true, decorated: false
    self.assert_file_equals_string "text/application_run5.txt", tester.display
  end

  def test_run_no_interaction : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    app.add FooCommand.new

    tester = ACON::Spec::ApplicationTester.new app

    tester.run command: "foo:bar", "--no-interaction": true, decorated: false
    tester.display.should eq "execute called\n"

    tester.run command: "foo:bar", "-n": true, decorated: false
    tester.display.should eq "execute called\n"
  end

  def test_run_global_option_and_no_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    app.definition << ACON::Input::Option.new "foo", "f", :optional

    input = ACON::Input::ARGV.new ["--foo", "bar"]

    app.run(input, ACON::Output::Null.new).should eq ACON::Command::Status::SUCCESS
  end

  def test_run_verbose_value_doesnt_break_arguments : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    app.add FooCommand.new

    output = ACON::Output::IO.new IO::Memory.new
    input = ACON::Input::ARGV.new ["-v", "foo:bar"]

    app.run(input, output).should eq ACON::Command::Status::SUCCESS

    input = ACON::Input::ARGV.new ["--verbose", "foo:bar"]

    app.run(input, output).should eq ACON::Command::Status::SUCCESS
  end

  def test_run_returns_status_with_custom_code_on_exception : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.register "foo" do
      raise ACON::Exceptions::Logic.new "", code: 5
    end

    input = ACON::Input::Hash.new({"command" => "foo"})

    app.run(input, ACON::Output::Null.new).value.should eq 5
  end

  def test_run_returns_failure_status_on_exception : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.register "foo" do
      raise ""
    end

    input = ACON::Input::Hash.new({"command" => "foo"})

    app.run(input, ACON::Output::Null.new).value.should eq 1
  end

  def test_add_option_duplicate_shortcut : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    app.definition << ACON::Input::Option.new "--env", "-e", :required, "Environment"

    app.register "foo" do
      ACON::Command::Status::SUCCESS
    end
      .aliases("f")
      .definition(
        ACON::Input::Option.new("survey", "e", :required, "Option with shortcut")
      )

    input = ACON::Input::Hash.new({"command" => "foo"})

    expect_raises ACON::Exceptions::Logic, "An option with shortcut 'e' already exists." do
      app.run input, ACON::Output::Null.new
    end
  end

  @[DataProvider("already_set_definition_element_provider")]
  def test_adding_already_set_definition_element(element) : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    app.register "foo" do
      ACON::Command::Status::SUCCESS
    end
      .definition(element)

    input = ACON::Input::Hash.new({"command" => "foo"})

    expect_raises ACON::Exceptions::Logic do
      app.run input, ACON::Output::Null.new
    end
  end

  def already_set_definition_element_provider : Tuple
    {
      {ACON::Input::Argument.new("command", :required)},
      {ACON::Input::Option.new("quiet", value_mode: :none)},
      {ACON::Input::Option.new("query", "q", :none)},
    }
  end

  def test_helper_set_contains_default_helpers : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    helper_set = app.helper_set

    helper_set.has?(ACON::Helper::Question).should be_true
    helper_set.has?(ACON::Helper::Formatter).should be_true
  end

  def test_adding_single_helper_overwrites_default : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    app.helper_set = ACON::Helper::HelperSet.new(ACON::Helper::Formatter.new)

    helper_set = app.helper_set
    helper_set.has?(ACON::Helper::Question).should be_false
    helper_set.has?(ACON::Helper::Formatter).should be_true
  end

  def test_default_input_definition_returns_default_values : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    definition = app.definition

    definition.has_argument?("command").should be_true

    definition.has_option?("help").should be_true
    definition.has_option?("quiet").should be_true
    definition.has_option?("verbose").should be_true
    definition.has_option?("version").should be_true
    definition.has_option?("ansi").should be_true
    definition.has_option?("no-interaction").should be_true
    definition.has_negation?("no-ansi").should be_true
    definition.has_option?("no-ansi").should be_false
  end

  # TODO: Test custom application type's helper set.

  def test_setting_custom_input_definition_overrides_default_values : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    app.definition = ACON::Input::Definition.new(
      ACON::Input::Option.new "--custom", "-c", :none, "Set the custom input definition"
    )

    definition = app.definition

    definition.has_argument?("command").should be_false

    definition.has_option?("help").should be_false
    definition.has_option?("quiet").should be_false
    definition.has_option?("verbose").should be_false
    definition.has_option?("version").should be_false
    definition.has_option?("ansi").should be_false
    definition.has_option?("no-interaction").should be_false
    definition.has_negation?("no-ansi").should be_false

    definition.has_option?("custom").should be_true
  end

  # TODO: Add dispatcher related specs

  def test_run_custom_default_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.add command = FooCommand.new
    app.default_command command.name

    tester = ACON::Spec::ApplicationTester.new app
    tester.run interactive: false
    tester.display.should eq "execute called\n"

    # TODO: Test custom application default.
  end

  def test_run_custom_default_command_with_option : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.add command = FooOptCommand.new
    app.default_command command.name

    tester = ACON::Spec::ApplicationTester.new app
    tester.run "--fooopt": "opt", interactive: false
    tester.display.should eq "execute called\nopt\n"
  end

  def test_run_custom_single_default_command : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.add command = FooOptCommand.new
    app.default_command command.name, true

    tester = ACON::Spec::ApplicationTester.new app

    tester.run
    tester.display.should contain "execute called"

    tester.run "--help": true
    tester.display.should contain "The foo:bar command"
  end

  def test_find_alternative_does_not_load_same_namespace_commands_on_exact_match : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false

    loaded = Hash(String, Bool).new

    app.command_loader = ACON::Loader::Factory.new({
      "foo:bar" => ->do
        loaded["foo:bar"] = true

        ACON::Commands::Generic.new("foo:bar") { ACON::Command::Status::SUCCESS }.as ACON::Command
      end,
      "foo" => ->do
        loaded["foo"] = true

        ACON::Commands::Generic.new("foo") { ACON::Command::Status::SUCCESS }.as ACON::Command
      end,
    })

    app.run ACON::Input::Hash.new({"command" => "foo"}), ACON::Output::Null.new

    loaded.should eq({"foo" => true})
  end

  def test_command_name_mismatch_with_command_loader_raises : Nil
    app = ACON::Application.new "foo"

    app.command_loader = ACON::Loader::Factory.new({
      "foo" => ->{ ACON::Commands::Generic.new("bar") { ACON::Command::Status::SUCCESS }.as ACON::Command },
    })

    expect_raises ACON::Exceptions::CommandNotFound, "The 'foo' command cannot be found because it is registered under multiple names. Make sure you don't set a different name via constructor or 'name='." do
      app.get "foo"
    end
  end
end
