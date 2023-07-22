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
      "optname minimal input" => {Input.from_tokens(["-"], 0), Input::Type::OPTION_NAME, nil, "-"},
      "optname partial"       => {Input.from_tokens(["--with"], 0), Input::Type::OPTION_NAME, nil, "--with"},

      # Option values
      "optvalue short"                => {Input.from_tokens(["-r"], 0), Input::Type::OPTION_VALUE, "with-required-value", ""},
      "optvalue short partial"        => {Input.from_tokens(["-rathe"], 0), Input::Type::OPTION_VALUE, "with-required-value", "athe"},
      "optvalue short space"          => {Input.from_tokens(["-r"], 1), Input::Type::OPTION_VALUE, "with-required-value", ""},
      "optvalue short space partial"  => {Input.from_tokens(["-r", "athe"], 1), Input::Type::OPTION_VALUE, "with-required-value", "athe"},
      "optvalue short before arg"     => {Input.from_tokens(["-r", "athena"], 0), Input::Type::OPTION_VALUE, "with-required-value", ""},
      "optvalue short optional"       => {Input.from_tokens(["-o"], 0), Input::Type::OPTION_VALUE, "with-optional-value", ""},
      "optvalue short space optional" => {Input.from_tokens(["-o"], 1), Input::Type::OPTION_VALUE, "with-optional-value", ""},

      "optvalue long"                => {Input.from_tokens(["--with-required-value="], 0), Input::Type::OPTION_VALUE, "with-required-value", ""},
      "optvalue long partial"        => {Input.from_tokens(["--with-required-value=ath"], 0), Input::Type::OPTION_VALUE, "with-required-value", "ath"},
      "optvalue long space"          => {Input.from_tokens(["--with-required-value"], 1), Input::Type::OPTION_VALUE, "with-required-value", ""},
      "optvalue long space partial"  => {Input.from_tokens(["--with-required-value", "ath"], 1), Input::Type::OPTION_VALUE, "with-required-value", "ath"},
      "optvalue long optional"       => {Input.from_tokens(["--with-optional-value="], 0), Input::Type::OPTION_VALUE, "with-optional-value", ""},
      "optvalue long space optional" => {Input.from_tokens(["--with-optional-value"], 1), Input::Type::OPTION_VALUE, "with-optional-value", ""},

      # Arguments
      "arg minimal input"         => {Input.from_tokens([] of String, 0), Input::Type::ARGUMENT_VALUE, "required-arg", ""},
      "arg optional"              => {Input.from_tokens(["athena"], 1), Input::Type::ARGUMENT_VALUE, "optional-arg", ""},
      "arg partial"               => {Input.from_tokens(["ath"], 0), Input::Type::ARGUMENT_VALUE, "required-arg", "ath"},
      "arg optional partial"      => {Input.from_tokens(["athena", "cry"], 1), Input::Type::ARGUMENT_VALUE, "optional-arg", "cry"},
      "arg after option"          => {Input.from_tokens(["--without-value"], 1), Input::Type::ARGUMENT_VALUE, "required-arg", ""},
      "arg after optional option" => {Input.from_tokens(["--with-optional-value", "--"], 2), Input::Type::ARGUMENT_VALUE, "required-arg", ""},

      # End of definition
      "end" => {Input.from_tokens(["athena", "crystal"], 2), Input::Type::NONE, nil, ""},
    }
  end
end
