require "./completion_output_test_case"

struct FishTest < CompletionOutputTestCase
  def completion_output : ACON::Completion::Output::Interface
    ACON::Completion::Output::Fish.new
  end

  def expected_options_output : String
    "--option1\n--negatable\n--no-negatable"
  end

  def expected_values_output : String
    "Green\nRed\nYellow"
  end
end
