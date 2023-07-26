require "../spec_helper"

@[ACONA::AsCommand("hello|ahoy", description: "Hello test command")]
private class HelloCommand < ACON::Command
  protected def configure : Nil
    self
      .argument("name", :required)
  end

  def complete(input : ACON::Completion::Input, suggestions : ACON::Completion::Suggestions) : Nil
    if input.must_suggest_argument_values_for? "name"
      suggestions.suggest_values "Athena", "Crystal", "Ruby"
    end
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

struct CompleteCommandTest < ASPEC::TestCase
  @command : ACON::Commands::Complete
  @application : ACON::Application
  @tester : ACON::Spec::CommandTester

  def initialize
    @command = ACON::Commands::Complete.new

    @application = ACON::Application.new "TEST"
    @application.add HelloCommand.new

    @command.application = @application

    @tester = ACON::Spec::CommandTester.new @command
  end

  def test_required_shell_option : Nil
    expect_raises ACON::Exceptions::RuntimeError, "The '--shell' option must be set." do
      self.execute
    end
  end

  def test_unsupported_shell_option : Nil
    expect_raises ACON::Exceptions::RuntimeError, "Shell completion is not supported for your shell: 'unsupported' (supported: 'bash', 'zsh')." do
      self.execute({"--shell" => "unsupported"})
    end
  end

  def test_completes_command_name_with_loader : Nil
    @application.command_loader = ACON::Loader::Factory.new({
      "foo:bar1" => ->{ Foo1Command.new.as ACON::Command },
    })

    self.execute({"--current" => "0", "--input" => [] of String})
    @tester.display.should eq "#{["help", "list", "completion", "hello", "ahoy", "foo:bar1", "afoobar1"].join("\n")}#{ACON::System::EOL}"
  end

  def test_additional_shell_support : Nil
    @command = ACON::Commands::Complete.new({"supported" => ACON::Completion::Output::Bash} of String => ACON::Completion::Output::Interface.class)
    @command.application = @application
    @tester = ACON::Spec::CommandTester.new @command

    self.execute({"--shell" => "supported", "--current" => "0", "--input" => [] of String})

    # Default shell should still be supported
    self.execute({"--shell" => "bash", "--current" => "0", "--input" => [] of String})
  end

  @[DataProvider("input_and_current_option_provider")]
  def test_input_and_current_option_validation(input : Hash(String, _), exception_message : String?) : Nil
    if exception_message
      expect_raises ::Exception, exception_message do
        self.execute input.merge!({"--shell" => "bash"})
      end

      return
    end

    self.execute input.merge!({"--shell" => "bash"})

    @tester.assert_command_is_successful
  end

  def input_and_current_option_provider : Tuple
    {
      {Hash(String, String).new, "The '--current' option must be set and it must be an integer"},
      { {"--current" => "a"}, "The '--current' option must be set and it must be an integer" },
      { {"--current" => "0", "--input" => [] of String}, nil },
      { {"--current" => "2", "--input" => [] of String}, "Current index is invalid, it must be the number of input tokens." },
      { {"--current" => "0", "--input" => [] of String}, nil },
      { {"--current" => "1", "--input" => ["foo:bar"] of String}, nil },
      { {"--current" => "2", "--input" => ["foo:bar", "bar"] of String}, nil },
    }
  end

  @[DataProvider("provide_complete_command_name_inputs")]
  def test_completion_command_name(input : Array(String), suggestions : Array(String)) : Nil
    self.execute({"--current" => "0", "--input" => input})
    @tester.display.should eq "#{suggestions.join("\n")}#{ACON::System::EOL}"
  end

  def provide_complete_command_name_inputs : Hash
    {
      "empty"                  => {[] of String, ["help", "list", "completion", "hello", "ahoy"]},
      "partial"                => {["he"], ["help", "list", "completion", "hello", "ahoy"]},
      "complete shortcut name" => {["hell"], ["hello", "ahoy"]},
      "complete alias"         => {["ah"], ["hello", "ahoy"]},
    }
  end

  @[DataProvider("provide_input_definition_inputs")]
  def test_completion_command_input_definitions(input : Array(String), suggestions : Array(String)) : Nil
    self.execute({"--current" => "1", "--input" => input})
    @tester.display.should eq "#{suggestions.join("\n")}#{ACON::System::EOL}"
  end

  def provide_input_definition_inputs : Hash
    {
      "definition"         => {["hello", "-"], ["--help", "--quiet", "--verbose", "--version", "--ansi", "--no-ansi", "--no-interaction"]},
      "custom"             => {["hello"], ["Athena", "Crystal", "Ruby"]},
      "aliased definition" => {["ahoy", "-"], ["--help", "--quiet", "--verbose", "--version", "--ansi", "--no-ansi", "--no-interaction"]},
      "aliased custom"     => {["ahoy"], ["Athena", "Crystal", "Ruby"]},
    }
  end

  private def execute(input : Hash(String, _) = {} of String => String) : Nil
    # Run in verbose mode to assert exceptions
    @tester.execute(
      (!input.empty? ? {"--shell" => "bash", "--api-version" => ACON::Commands::Complete::API_VERSION.to_s}.merge(input) : input),
      verbosity: ACON::Output::Verbosity::DEBUG
    )
  end
end
