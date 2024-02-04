require "../spec_helper"
require "./abstract_question_helper_test_case"

struct AthenaQuestionTest < AbstractQuestionHelperTest
  @helper : ACON::Helper::Question

  def initialize
    @helper = ACON::Helper::AthenaQuestion.new

    super
  end

  def test_ask_choice_question : Nil
    heroes = ["Superman", "Batman", "Spiderman"]
    self.with_input "\n1\n  1  \nGeorge\n1\nGeorge" do |input|
      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 2
      question.max_attempts = 1

      # First answer is empty, so should use default
      @helper.ask(input, @output, question).should eq "Spiderman"
      self.assert_output_contains "Who is your favorite superhero? [Spiderman]"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq "Batman"
      @helper.ask(input, @output, question).should eq "Batman"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
      question.error_message = "Input '%s' is not a superhero!"
      question.max_attempts = 2

      @helper.ask(input, @output, question).should eq "Batman"
      self.assert_output_contains "Input 'George' is not a superhero!"

      begin
        question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 1
        question.max_attempts = 1
        @helper.ask input, @output, question
      rescue ex : ACON::Exceptions::InvalidArgument
        ex.message.should eq "Value 'George' is invalid."
      end
    end
  end

  def test_ask_multiple_choice : Nil
    heroes = ["Superman", "Batman", "Spiderman"]

    self.with_input "1\n0,2\n 0 , 2  \n\n\n" do |input|
      question = ACON::Question::MultipleChoice.new "Who is your favorite superhero?", heroes
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Batman"]
      @helper.ask(input, @output, question).should eq ["Superman", "Spiderman"]
      @helper.ask(input, @output, question).should eq ["Superman", "Spiderman"]

      question = ACON::Question::MultipleChoice.new "Who is your favorite superhero?", heroes, "0,1"
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]
      self.assert_output_contains "Who is your favorite superhero? [Superman, Batman]"

      question = ACON::Question::MultipleChoice.new "Who is your favorite superhero?", heroes, " 0 , 1 "
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]
      self.assert_output_contains "Who is your favorite superhero? [Superman, Batman]"
    end
  end

  def test_ask_choice_with_choice_value_as_default : Nil
    question = ACON::Question::Choice.new "Who is your favorite superhero?", ["Superman", "Batman", "Spiderman"], "Batman"
    question.max_attempts = 1

    self.with_input "Batman\n" do |input|
      @helper.ask(input, @output, question).should eq "Batman"
    end

    self.assert_output_contains "Who is your favorite superhero? [Batman]"
  end

  def test_ask_returns_nil_if_validator_allows_it : Nil
    question = ACON::Question(String?).new "Who is your favorite superhero?", nil
    question.validator do |value|
      value
    end

    self.with_input "\n" do |input|
      @helper.ask(input, @output, question).should be_nil
    end
  end

  def test_ask_escapes_default_value : Nil
    self.with_input "\\" do |input|
      question = ACON::Question.new "Can I have a backslash?", "\\"

      @helper.ask input, @output, question
      self.assert_output_contains %q(Can I have a backslash? [\])
    end
  end

  def test_ask_format_and_escape_label : Nil
    question = ACON::Question.new %q(Do you want to use Foo\Bar <comment>or</comment> Foo\Baz\?), "Foo\\Baz"

    self.with_input "Foo\\Bar" do |input|
      @helper.ask input, @output, question
    end

    self.assert_output_contains %q( Do you want to use Foo\Bar or Foo\Baz\? [Foo\Baz]:)
  end

  def test_ask_label_trailing_backslash : Nil
    question = ACON::Question(String?).new "Question with a trailing \\", nil

    self.with_input "sure" do |input|
      @helper.ask input, @output, question
    end

    self.assert_output_contains "Question with a trailing \\"
  end

  def test_ask_raises_on_missing_input : Nil
    self.with_input "" do |input|
      question = ACON::Question(String?).new "What's your name?", nil

      expect_raises ACON::Exceptions::MissingInput, "Aborted." do
        @helper.ask input, @output, question
      end
    end
  end

  def test_ask_choice_question_padding : Nil
    question = ACON::Question::Choice.new "qqq", {"foo" => "foo", "żółw" => "bar", "łabądź" => "baz"}
    self.with_input "foo\n" do |input|
      @helper.ask input, @output, question
    end

    self.assert_output_contains <<-OUT, true
     qqq:
      [foo   ] foo
      [żółw  ] bar
      [łabądź] baz
     >
    OUT
  end

  def test_ask_choice_question_custom_prompt : Nil
    question = ACON::Question::Choice.new "qqq", {"foo"}
    question.prompt = " >ccc> "

    self.with_input "foo\n" do |input|
      @helper.ask input, @output, question
    end

    self.assert_output_contains <<-OUT, true
     qqq:
      [0] foo
     >ccc>
    OUT
  end

  def test_ask_multiline_question_includes_help_text : Nil
    expected = "Write an essay (press Ctrl+D to continue)"

    # TODO: Update expected message on windows
    # expected = "Write an essay (press Ctrl+Z then Enter to continue)"

    question = ACON::Question(String?).new "Write an essay", nil
    question.multi_line = true

    self.with_input "\\" do |input|
      @helper.ask input, @output, question
    end

    self.assert_output_contains expected
  end
end
