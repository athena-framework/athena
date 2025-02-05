require "../spec_helper"

private alias Input = ACON::Completion::Input

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
    input.must_suggest_option_values_for?("with-required-value").should be_true if expected_value.starts_with? "athe"
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

  @[DataProvider("last_array_argument_provider")]
  def test_bind_with_last_array_argument(input : Input, expected_value : String?) : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Argument.new("list-arg", ACON::Input::Argument::Mode[:required, :is_array]),
    )

    input.bind definition

    input.completion_type.should eq Input::Type::ARGUMENT_VALUE
    input.completion_name.should eq "list-arg"
    input.completion_value.should eq expected_value
  end

  def last_array_argument_provider : Tuple
    {
      {Input.from_tokens([] of String, 0), ""},
      {Input.from_tokens(["athena", "crystal"], 2), ""},
      {Input.from_tokens(["athena", "cry"], 1), "cry"},
    }
  end

  def test_bind_argument_with_default : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Argument.new("arg-with-default", :optional, default: "default"),
    )

    input = Input.from_tokens [] of String, 0
    input.bind definition

    input.completion_type.should eq Input::Type::ARGUMENT_VALUE
    input.completion_name.should eq "arg-with-default"
    input.completion_value.should eq ""
    input.must_suggest_argument_values_for?("arg-with-default").should be_true
  end

  @[DataProvider("from_string_provider")]
  def test_from_string(input_string : String, expected_tokens : Array(String)) : Nil
    input = Input.from_string input_string, 1

    input.@tokens.should eq expected_tokens
  end

  def from_string_provider : Tuple
    {
      {"do:thing", ["do:thing"]},
      {"--env prod", ["--env", "prod"]},
      {"--env=prod", ["--env=prod"]},
      {"-eprod", ["-eprod"]},
      { %(do:thing "multi word string"), ["do:thing", %("multi word string")] },
      {"do:thing 'multi word string'", ["do:thing", "'multi word string'"]},
    }
  end
end
