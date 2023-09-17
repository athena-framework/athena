abstract struct CompletionOutputTestCase < ASPEC::TestCase
  abstract def completion_output : ACON::Completion::Output::Interface
  abstract def expected_options_output : String
  abstract def expected_values_output : String

  def test_options : Nil
    options = [
      ACON::Input::Option.new("option1", "o", :none, "First Option"),
      ACON::Input::Option.new("negatable", nil, :negatable, "Can be negative"),
    ]

    suggestions = ACON::Completion::Suggestions.new
    suggestions.suggest_options options

    buffer = IO::Memory.new

    self.completion_output.write suggestions, ACON::Output::IO.new buffer

    buffer.to_s.should eq self.expected_options_output
  end

  def test_values : Nil
    suggestions = ACON::Completion::Suggestions.new
    suggestions.suggest_value "Green", "Beans are green"
    suggestions.suggest_value "Red", "Roses are red"
    suggestions.suggest_value "Yellow", "Canaries are yellow"

    buffer = IO::Memory.new

    self.completion_output.write suggestions, ACON::Output::IO.new buffer

    buffer.to_s.should eq self.expected_values_output
  end
end
