require "../spec_helper"

struct DumpCompletionCommandTest < ASPEC::TestCase
  @[DataProvider("complete_provider")]
  def test_complete(input : Array(String), expected_suggestions : Array(String)) : Nil
    tester = ACON::Spec::CommandCompletionTester.new ACON::Commands::DumpCompletion.new
    suggestions = tester.complete input

    suggestions.should eq expected_suggestions
  end

  def complete_provider : Hash
    {
      "shell" => {[] of String, ["bash", "zsh"]},
    }
  end
end
