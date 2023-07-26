require "./completion_output_test_case"

struct ZshTest < CompletionOutputTestCase
  def completion_output : ACON::Completion::Output::Interface
    ACON::Completion::Output::Zsh.new
  end

  def expected_options_output : String
    "--option1\tFirst Option\n--negatable\tCan be negative\n--no-negatable\tCan be negative\n"
  end

  def expected_values_output : String
    "Green\tBeans are green\nRed\tRoses are red\nYellow\tCanaries are yellow\n"
  end
end
