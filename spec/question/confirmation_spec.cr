require "../spec_helper"

struct ConfirmationQuestionTest < ASPEC::TestCase
  @[DataProvider("normalizer_provider")]
  def test_default_regex(default : Bool, answers : Array, expected : Bool) : Nil
    question = ACON::Question::Confirmation.new "A question", default

    answers.each do |answer|
      normalizer = question.normalizer.not_nil!
      actual = normalizer.call answer
      actual.should eq expected
    end
  end

  def normalizer_provider : Tuple
    {
      {
        true,
        ["y", "Y", "yes", "YES", "yEs", ""],
        true,
      },
      {
        true,
        ["n", "N", "no", "NO", "nO", "foo", "1", "0"],
        false,
      },
      {
        false,
        ["y", "Y", "yes", "YES", "yEs"],
        true,
      },
      {
        false,
        ["n", "N", "no", "NO", "nO", "foo", "1", "0", ""],
        false,
      },
    }
  end
end
