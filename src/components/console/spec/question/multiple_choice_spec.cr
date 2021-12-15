require "../spec_helper"

struct MultipleChoiceQuestionTest < ASPEC::TestCase
  def test_new_empty_choices : Nil
    expect_raises ACON::Exceptions::Logic, "Choice questions must have at least 1 choice available." do
      ACON::Question::MultipleChoice.new "A question", Array(String).new
    end
  end

  def test_non_trimmable : Nil
    question = ACON::Question::MultipleChoice(String).new(
      "A question",
      [
        "First response ",
        " Second response",
        "  Third response  ",
      ]
    )

    question.trimmable = false

    question.validator.not_nil!.call("First response , Second response").should eq ["First response ", " Second response"]
  end

  @[DataProvider("hash_choice_provider")]
  def test_validator_hash_choices(answer : String, expected : Array) : Nil
    question = ACON::Question::MultipleChoice.new(
      "A question",
      {
        "0"   => "First choice",
        "foo" => "Foo",
        "99"  => "N°99",
      }
    )

    question.validator.not_nil!.call(answer).should eq expected
  end

  def hash_choice_provider : Hash
    {
      "'0' choice by key - multiple" => {"0,Foo", ["First choice", "Foo"]},
      "'0' choice by key- single"    => {"foo", ["Foo"]},
      "select by value, numeric key" => {"N°99,foo,First choice", ["N°99", "Foo", "First choice"]},
    }
  end
end
