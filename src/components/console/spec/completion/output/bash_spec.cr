require "./completion_output_test_case"

struct BashTest < CompletionOutputTestCase
  def completion_output : ACON::Completion::Output::Interface
    ACON::Completion::Output::Bash.new
  end

  def expected_options_output : String
    "--option1\n--negatable\n--no-negatable#{ACON::System::EOL}"
  end

  def expected_values_output : String
    "Green\nRed\nYellow#{ACON::System::EOL}"
  end
end
