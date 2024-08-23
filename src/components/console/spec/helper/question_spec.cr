require "../spec_helper"
require "./abstract_question_helper_test_case"

struct QuestionHelperTest < AbstractQuestionHelperTest
  @helper : ACON::Helper::Question

  def initialize
    @helper = ACON::Helper::Question.new

    super
  end

  def test_ask_choice_question : Nil
    heroes = ["Superman", "Batman", "Spiderman"]
    self.with_input "\n1\n  1  \nGeorge\n1\nGeorge\n\n\n" do |input|
      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 2
      question.max_attempts = 1

      # First answer is empty, so should use default
      @helper.ask(input, @output, question).should eq "Spiderman"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq "Batman"
      @helper.ask(input, @output, question).should eq "Batman"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
      question.error_message = "Input '%s' is not a superhero!"
      question.max_attempts = 2

      @helper.ask(input, @output, question).should eq "Batman"

      begin
        question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 1
        question.max_attempts = 1
        @helper.ask input, @output, question
      rescue ex : ACON::Exception::InvalidArgument
        ex.message.should eq "Value 'George' is invalid."
      end

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, "0"
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq "Superman"
    end
  end

  def test_ask_choice_question_non_interactive : Nil
    heroes = ["Superman", "Batman", "Spiderman"]
    self.with_input "\n1\n  1  \nGeorge\n1\nGeorge\n1\n", false do |input|
      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 0
      @helper.ask(input, @output, question).should eq "Superman"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, "Batman"
      @helper.ask(input, @output, question).should eq "Batman"

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
      @helper.ask(input, @output, question).should be_nil

      question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes, 0
      question.validator = nil
      @helper.ask(input, @output, question).should eq "Superman"

      begin
        question = ACON::Question::Choice.new "Who is your favorite superhero?", heroes
        @helper.ask input, @output, question
      rescue ex : ACON::Exception::InvalidArgument
        ex.message.should eq "Value '' is invalid."
      end
    end
  end

  def test_ask_multiple_choice : Nil
    heroes = ["Superman", "Batman", "Spiderman"]

    self.with_input "1\n0,2\n 0 , 2  \n\n\n" do |input|
      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Batman"]
      @helper.ask(input, @output, question).should eq ["Superman", "Spiderman"]
      @helper.ask(input, @output, question).should eq ["Superman", "Spiderman"]

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, "0,1"
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, " 0 , 1 "
      question.max_attempts = 1

      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]
    end
  end

  def test_ask_multiple_choice_non_interactive : Nil
    heroes = ["Superman", "Batman", "Spiderman"]

    self.with_input "1\n0,2\n 0 , 2  ", false do |input|
      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, "0,1"
      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, " 0 , 1 "
      question.validator = nil
      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, "0,Batman"
      @helper.ask(input, @output, question).should eq ["Superman", "Batman"]

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes
      @helper.ask(input, @output, question).should be_nil

      question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", {"a" => "Batman", "b" => "Superman"}, "a"
      @helper.ask(input, @output, question).should eq ["Batman"]

      begin
        question = ACON::Question::MultipleChoice.new "Who are your favorite superheros?", heroes, ""
        @helper.ask input, @output, question
      rescue ex : ACON::Exception::InvalidArgument
        ex.message.should eq "Value '' is invalid."
      end
    end
  end

  def test_ask : Nil
    self.with_input "\n8AM\n" do |input|
      question = ACON::Question.new "What time is it?", "2PM"
      @helper.ask(input, @output, question).should eq "2PM"

      question = ACON::Question.new "What time is it?", "2PM"
      @helper.ask(input, @output, question).should eq "8AM"

      self.assert_output_contains "What time is it?"
    end
  end

  def test_ask_non_trimmed : Nil
    question = ACON::Question.new "What time is it?", "2PM"
    question.trimmable = false

    self.with_input " 8AM " do |input|
      @helper.ask(input, @output, question).should eq " 8AM "
    end

    self.assert_output_contains "What time is it?"
  end

  # TODO: Add autocompleter tests

  def test_ask_hidden : Nil
    question = ACON::Question.new "What time is it?", "2PM"
    question.hidden = true

    self.with_input "8AM\n" do |input|
      @helper.ask(input, @output, question).should eq "8AM"
    end

    self.assert_output_contains "What time is it?"
  end

  def test_ask_hidden_non_trimmed : Nil
    question = ACON::Question.new "What time is it?", "2PM"
    question.hidden = true
    question.trimmable = false

    self.with_input " 8AM" do |input|
      @helper.ask(input, @output, question).should eq " 8AM"
    end

    self.assert_output_contains "What time is it?"
  end

  def test_ask_multi_line : Nil
    essay = <<-ESSAY
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque pretium lectus quis suscipit porttitor. Sed pretium bibendum vestibulum.

    Etiam accumsan, justo vitae imperdiet aliquet, neque est sagittis mauris, sed interdum massa leo id leo.

    Aliquam rhoncus, libero ac blandit convallis, est sapien hendrerit nulla, vitae aliquet tellus orci a odio. Aliquam gravida ante sit amet massa lacinia, ut condimentum purus venenatis.

    Vivamus et erat dictum, euismod neque in, laoreet odio. Aenean vitae tellus at leo vestibulum auctor id eget urna.
    ESSAY

    question = ACON::Question(String?).new "Write an essay", nil
    question.multi_line = true

    self.with_input essay do |input|
      @helper.ask(input, @output, question).should eq essay
    end
  end

  def test_ask_multi_line_response_with_single_newline : Nil
    question = ACON::Question(String?).new "Write an essay", nil
    question.multi_line = true

    self.with_input "\n" do |input|
      @helper.ask(input, @output, question).should be_nil
    end
  end

  def test_ask_multi_line_response_with_data_after_newline : Nil
    question = ACON::Question(String?).new "Write an essay", nil
    question.multi_line = true

    self.with_input "\nSome Text" do |input|
      @helper.ask(input, @output, question).should be_nil
    end
  end

  def test_ask_multi_line_response_multiple_newlines_at_end : Nil
    question = ACON::Question(String?).new "Write an essay", nil
    question.multi_line = true

    self.with_input "Some Text\n\n" do |input|
      @helper.ask(input, @output, question).should eq "Some Text"
    end
  end

  @[DataProvider("confirmation_provider")]
  def test_ask_confirmation(answer : String, expected : Bool, default : Bool) : Nil
    question = ACON::Question::Confirmation.new "Some question", default

    self.with_input "#{answer}\n" do |input|
      @helper.ask(input, @output, question).should eq expected
    end
  end

  def confirmation_provider : Tuple
    {
      {"", true, true},
      {"", false, false},
      {"y", true, false},
      {"yes", true, false},
      {"n", false, true},
      {"no", false, true},
    }
  end

  def test_ask_confirmation_custom_true_answer : Nil
    question = ACON::Question::Confirmation.new "Some question", false, /^(j|y)/i

    self.with_input "j\ny\n" do |input|
      @helper.ask(input, @output, question).should be_true
      @helper.ask(input, @output, question).should be_true
    end
  end

  def test_ask_and_validate : Nil
    error = "This is not a color!"

    question = ACON::Question.new " What is your favorite color?", "white"
    question.max_attempts = 2
    question.validator do |answer|
      raise ACON::Exception::Runtime.new error unless answer.in? "white", "black"

      answer
    end

    self.with_input "\nblack\n" do |input|
      @helper.ask(input, @output, question).should eq "white"
      @helper.ask(input, @output, question).should eq "black"
    end

    self.with_input "green\nyellow\norange\n" do |input|
      expect_raises ACON::Exception::Runtime, error do
        @helper.ask input, @output, question
      end
    end
  end

  @[DataProvider("simple_answer_provider")]
  def test_ask_choice_simple_answers(answer, expected : String) : Nil
    choices = [
      "My environment 1",
      "My environment 2",
      "My environment 3",
    ]

    question = ACON::Question::Choice.new "Please select the environment to load", choices
    question.max_attempts = 1

    self.with_input "#{answer}\n" do |input|
      @helper.ask(input, @output, question).should eq expected
    end
  end

  def simple_answer_provider : Tuple
    {
      {0, "My environment 1"},
      {1, "My environment 2"},
      {2, "My environment 3"},
      {"My environment 1", "My environment 1"},
      {"My environment 2", "My environment 2"},
      {"My environment 3", "My environment 3"},
    }
  end

  @[DataProvider("special_character_provider")]
  def test_ask_special_characters_multiple_choice(answer : String, expected : Array(String)) : Nil
    choices = [
      ".",
      "src",
    ]

    question = ACON::Question::MultipleChoice.new "Please select the environment to load", choices
    question.max_attempts = 1

    self.with_input "#{answer}\n" do |input|
      @helper.ask(input, @output, question).should eq expected
    end
  end

  def special_character_provider : Tuple
    {
      {".", ["."]},
      {".,src", [".", "src"]},
    }
  end

  @[DataProvider("answer_provider")]
  def test_ask_choice_hash_choices(answer : String, expected : String) : Nil
    choices = {
      "env_1" => "My environment 1",
      "env_2" => "My environment",
      "env_3" => "My environment",
    }

    question = ACON::Question::Choice.new "Please select the environment to load", choices
    question.max_attempts = 1

    self.with_input "#{answer}\n" do |input|
      @helper.ask(input, @output, question).should eq expected
    end
  end

  def answer_provider : Tuple
    {
      {"env_1", "My environment 1"},
      {"env_2", "My environment"},
      {"env_3", "My environment"},
      {"My environment 1", "My environment 1"},
    }
  end

  def test_ask_ambiguous_choice : Nil
    choices = {
      "env_1" => "My first environment",
      "env_2" => "My environment",
      "env_3" => "My environment",
    }

    question = ACON::Question::Choice.new "Please select the environment to load", choices
    question.max_attempts = 1

    self.with_input "My environment\n" do |input|
      expect_raises ACON::Exception::InvalidArgument, "The provided answer is ambiguous. Value should be one of 'env_2' or 'env_3'." do
        @helper.ask input, @output, question
      end
    end
  end

  def test_ask_non_interactive : Nil
    question = ACON::Question.new "Some question", "some answer"

    self.with_input "yes", false do |input|
      @helper.ask(input, @output, question).should eq "some answer"
    end
  end

  def test_ask_raises_on_missing_input : Nil
    question = ACON::Question.new "Some question", "some answer"

    self.with_input "" do |input|
      expect_raises ACON::Exception::MissingInput, "Aborted." do
        @helper.ask input, @output, question
      end
    end
  end

  # TODO: What to do if the input is ""?

  def test_question_validator_repeats_the_prompt : Nil
    tries = 0

    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.register "question" do |input, output|
      question = ACON::Question(String?).new "This is a promptable question", nil
      question.validator do |answer|
        tries += 1

        raise "" unless answer.presence

        answer
      end

      ACON::Helper::Question.new.ask input, output, question

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::ApplicationTester.new app
    tester.inputs = ["", "not-empty"]

    tester.run(command: "question", interactive: true).should eq ACON::Command::Status::SUCCESS
    tries.should eq 2
  end
end
