require "../spec_helper"

private class QuestionCommand < ACON::Command
  protected def configure : Nil
    self
      .name("question:command")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    name = self.helper(ACON::Helper::Question).ask input, output, ACON::Question(String?).new "What is your name?", nil

    output.puts "Your name is: #{name}"

    ACON::Command::Status::SUCCESS
  end
end

struct QuestionTest < ASPEC::TestCase
  @question : ACON::Question(String?)

  def initialize
    @question = ACON::Question(String?).new "Test Question", nil
  end

  def test_default : Nil
    @question.default.should be_nil
    default = ACON::Question(String).new("Test Question", "FOO").default
    default.should eq "FOO"
    typeof(default).should eq String
  end

  def test_hidden_autocompleter_callback : Nil
    @question.autocompleter_callback do
      [] of String
    end

    expect_raises ACON::Exception::Logic, "A hidden question cannot use the autocompleter" do
      @question.hidden = true
    end
  end

  @[DataProvider("autocompleter_values_provider")]
  def test_get_set_autocompleter_values(values : Indexable | Hash, expected : Array(String)) : Nil
    @question.autocompleter_values = values

    @question.autocompleter_values.should eq expected
  end

  def autocompleter_values_provider : Hash
    {
      "tuple" => {
        {"a", "b", "c"},
        ["a", "b", "c"],
      },
      "array" => {
        ["a", "b", "c"],
        ["a", "b", "c"],
      },
      "string key hash" => {
        {"a" => "b", "c" => "d"},
        ["a", "c", "b", "d"],
      },
      "int key hash" => {
        {0 => "b", 1 => "d"},
        ["b", "d"],
      },
    }
  end

  def test_custom_normalizer : Nil
    question = ACON::Question(String).new "A question", ""

    question.normalizer do |val|
      val.upcase
    end

    if normalizer = question.normalizer
      normalizer.call("foo").should eq "FOO"
    end
  end

  def test_with_inputs : Nil
    command = QuestionCommand.new
    command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new
    tester = ACON::Spec::CommandTester.new command
    tester.inputs "Jim"
    tester.execute
    tester.display.should eq "What is your name?Your name is: Jim#{EOL}"
  end
end
