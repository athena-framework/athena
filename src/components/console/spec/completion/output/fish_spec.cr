require "./completion_output_test_case"

struct FishTest < CompletionOutputTestCase
  def completion_output : ACON::Completion::Output::Interface
    ACON::Completion::Output::Fish.new
  end

  def expected_options_output : String
    "--option1\tFirst Option\n--negatable\tCan be negative\n--no-negatable\tCan be negative"
  end

  def expected_values_output : String
    "Green\tBeans are green\nRed\tRoses are red\nYellow\tCanaries are yellow"
  end

  def test_without_descriptions : Nil
    suggestions = ACON::Completion::Suggestions.new
    suggestions.suggest_values "Green", "Red"
    suggestions.suggest_option ACON::Input::Option.new("negatable", nil, :negatable)

    buffer = IO::Memory.new

    self.completion_output.write suggestions, ACON::Output::IO.new buffer

    buffer.to_s.should eq "Green\nRed\n--negatable\n--no-negatable"
  end
end
