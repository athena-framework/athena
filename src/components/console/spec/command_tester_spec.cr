require "./spec_helper"

struct CommandTesterTest < ASPEC::TestCase
  @command : ACON::Command
  @tester : ACON::Spec::CommandTester

  def initialize
    @command = ACON::Commands::Generic.new "foo" do |_, output|
      output.puts "foo"

      ACON::Command::Status::SUCCESS
    end
    @command.argument "command"
    @command.argument "foo"

    @tester = ACON::Spec::CommandTester.new @command
    @tester.execute foo: "bar", interactive: false, decorated: false, verbosity: :verbose
  end

  def test_execute : Nil
    @tester.input.interactive?.should be_false
    @tester.output.decorated?.should be_false
    @tester.output.verbosity.verbose?.should be_true
  end

  def test_input : Nil
    @tester.input.argument("foo").should eq "bar"
  end

  def test_output : Nil
    @tester.output.to_s.should eq "foo#{EOL}"
  end

  def test_display : Nil
    @tester.display.to_s.should eq "foo#{EOL}"
  end

  def test_display_before_calling_execute : Nil
    tester = ACON::Spec::CommandTester.new ACON::Commands::Generic.new "foo" { ACON::Command::Status::SUCCESS }

    expect_raises ACON::Exception::Logic, "Output not initialized. Did you execute the command before requesting the display?" do
      tester.display
    end
  end

  def test_status_code : Nil
    @tester.status.should eq ACON::Command::Status::SUCCESS
  end

  def test_command_from_application : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false

    app.register "foo" { |_, output| output.puts "foo"; ACON::Command::Status::SUCCESS }

    tester = ACON::Spec::CommandTester.new app.find "foo"

    tester.execute.should eq ACON::Command::Status::SUCCESS
  end

  def test_command_with_inputs : Nil
    questions = {
      "What is your name?",
      "How are you?",
      "Where do you come from?",
    }

    command = ACON::Commands::Generic.new "foo" do |input, output, c|
      helper = c.helper ACON::Helper::Question

      helper.ask input, output, ACON::Question(String?).new questions[0], nil
      helper.ask input, output, ACON::Question(String?).new questions[1], nil
      helper.ask input, output, ACON::Question(String?).new questions[2], nil

      ACON::Command::Status::SUCCESS
    end
    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new

    tester = ACON::Spec::CommandTester.new command
    tester.inputs = ["Bobby", "Fine", "Germany"]
    tester.execute

    tester.status.should eq ACON::Command::Status::SUCCESS
    tester.display.should eq questions.join
  end

  def test_command_with_inputs_with_defaults : Nil
    questions = {
      "What is your name?",
      "How are you?",
      "Where do you come from?",
    }

    command = ACON::Commands::Generic.new "foo" do |input, output, c|
      helper = c.helper ACON::Helper::Question

      helper.ask input, output, ACON::Question(String).new questions[0], "Bobby"
      helper.ask input, output, ACON::Question(String).new questions[1], "Fine"
      helper.ask input, output, ACON::Question(String).new questions[2], "Estonia"

      ACON::Command::Status::SUCCESS
    end
    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new

    tester = ACON::Spec::CommandTester.new command
    tester.inputs = ["", "", ""]
    tester.execute

    tester.status.should eq ACON::Command::Status::SUCCESS
    tester.display.should eq questions.join
  end

  def test_command_with_inputs_wrong_input_amount : Nil
    questions = {
      "What is your name?",
      "How are you?",
      "Where do you come from?",
    }

    command = ACON::Commands::Generic.new "foo" do |input, output, c|
      helper = c.helper ACON::Helper::Question

      helper.ask input, output, ACON::Question::Choice.new "choice", {"a", "b"}
      helper.ask input, output, ACON::Question(String?).new questions[0], nil
      helper.ask input, output, ACON::Question(String?).new questions[1], nil
      helper.ask input, output, ACON::Question(String?).new questions[2], nil

      ACON::Command::Status::SUCCESS
    end
    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new

    tester = ACON::Spec::CommandTester.new command
    tester.inputs = ["a", "Bobby", "Fine"]

    expect_raises ACON::Exception::MissingInput, "Aborted." do
      tester.execute
    end
  end

  def ptest_command_with_questions_but_no_input : Nil
    questions = {
      "What is your name?",
      "How are you?",
      "Where do you come from?",
    }

    command = ACON::Commands::Generic.new "foo" do |input, output, c|
      helper = c.helper ACON::Helper::Question

      helper.ask input, output, ACON::Question::Choice.new "choice", {"a", "b"}
      helper.ask input, output, ACON::Question(String?).new questions[0], nil
      helper.ask input, output, ACON::Question(String?).new questions[1], nil
      helper.ask input, output, ACON::Question(String?).new questions[2], nil

      ACON::Command::Status::SUCCESS
    end
    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new

    tester = ACON::Spec::CommandTester.new command

    expect_raises ACON::Exception::MissingInput, "Aborted." do
      tester.execute
    end
  end

  def test_athena_style_command_with_inputs : Nil
    questions = {
      "What is your name?",
      "How are you?",
      "Where do you come from?",
    }

    command = ACON::Commands::Generic.new "foo" do |input, output|
      style = ACON::Style::Athena.new input, output

      style.ask ACON::Question(String?).new questions[0], nil
      style.ask ACON::Question(String?).new questions[1], nil
      style.ask ACON::Question(String?).new questions[2], nil

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::CommandTester.new command
    tester.inputs = ["Bobby", "Fine", "France"]
    tester.execute.should eq ACON::Command::Status::SUCCESS
  end

  def test_error_output : Nil
    command = ACON::Commands::Generic.new "foo" do |_, output|
      output.as(ACON::Output::ConsoleOutput).error_output.print "foo"

      ACON::Command::Status::SUCCESS
    end
    command.argument "command"
    command.argument "foo"

    tester = ACON::Spec::CommandTester.new command
    tester.execute foo: "bar", capture_stderr_separately: true

    tester.error_output.should eq "foo"
  end
end
