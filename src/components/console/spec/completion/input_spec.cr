require "../spec_helper"

private alias Input = ACON::Completion::Input

@[ASPEC::TestCase::Focus]
struct CompletionInputTest < ASPEC::TestCase
  @[DataProvider("bind_data_provider")]
  def test_bind(input : Input, expected_type : Input::Type, expected_name : String?, expected_value : String) : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Option.new("with-required-value", "r", :required),
      ACON::Input::Option.new("with-optional-value", "o", :optional),
      ACON::Input::Option.new("without-value", "n", :none),
      ACON::Input::Argument.new("required-arg", :required),
      ACON::Input::Argument.new("optional-arg", :optional),
    )

    input.bind definition

    input.completion_type.should eq expected_type
    input.completion_name.should eq expected_name
    input.completion_value.should eq expected_value
  end

  def bind_data_provider : Hash
    {
      # Option names
      "optname minimal input" => {Input.from_tokens(["bin/console", "-"], 1), Input::Type::OPTION_NAME, nil, "-"},
      "optname partial"       => {Input.from_tokens(["bin/console", "--with"], 1), Input::Type::OPTION_NAME, nil, "--with"},

      # Option values
      "optvalue short" => {Input.from_tokens(["bin/console", "-r"], 1), Input::Type::OPTION_VALUE, "with-required-value", ""},
    }
  end
end
