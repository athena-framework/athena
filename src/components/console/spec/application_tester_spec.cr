require "./spec_helper"

struct ApplicationTesterTest < ASPEC::TestCase
  @app : ACON::Application
  @tester : ACON::Spec::ApplicationTester

  def initialize
    @app = ACON::Application.new "foo"
    @app.auto_exit = false

    @app.register "foo" do |_, output|
      output.puts "foo"

      ACON::Command::Status::SUCCESS
    end.argument "foo"

    @tester = ACON::Spec::ApplicationTester.new @app
    @tester.run command: "foo", foo: "bar", interactive: false, decorated: false, verbosity: :verbose
  end

  def test_run : Nil
    @tester.input.interactive?.should be_false
    @tester.output.decorated?.should be_false
    @tester.output.verbosity.verbose?.should be_true
  end

  def test_input : Nil
    @tester.input.argument("foo").should eq "bar"
  end

  def test_output : Nil
    @tester.output.to_s.should eq "foo#{ACON::System::EOL}"
  end

  def test_display : Nil
    @tester.display.to_s.should eq "foo#{ACON::System::EOL}"
  end

  def test_status : Nil
    @tester.status.should eq ACON::Command::Status::SUCCESS
  end

  def test_inputs : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.register "foo" do |input, output|
      helper = ACON::Helper::Question.new

      helper.ask input, output, ACON::Question(String?).new "Q1", nil
      helper.ask input, output, ACON::Question(String?).new "Q2", nil
      helper.ask input, output, ACON::Question(String?).new "Q3", nil

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::ApplicationTester.new app
    tester.inputs = ["A1", "A2", "A3"]
    tester.run command: "foo"

    tester.status.should eq ACON::Command::Status::SUCCESS
    tester.display.should eq "Q1Q2Q3"
  end

  def test_error_output : Nil
    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.register "foo" do |_, output|
      output.as(ACON::Output::ConsoleOutput).error_output.print "foo"

      ACON::Command::Status::SUCCESS
    end.argument "foo"

    tester = ACON::Spec::ApplicationTester.new app
    tester.run command: "foo", foo: "bar", capture_stderr_separately: true

    tester.error_output.should eq "foo"
  end
end
