require "../spec_helper"

struct ARGVTest < ASPEC::TestCase
  def test_parse : Nil
    input = ACON::Input::ARGV.new ["foo"]

    input.bind ACON::Input::Definition.new ACON::Input::Argument.new "name"
    input.arguments.should eq({"name" => "foo"})

    input.bind ACON::Input::Definition.new ACON::Input::Argument.new "name"
    input.arguments.should eq({"name" => "foo"})
  end

  def test_array_argument : Nil
    input = ACON::Input::ARGV.new ["foo", "bar", "baz", "bat"]
    input.bind ACON::Input::Definition.new ACON::Input::Argument.new "name", :is_array

    input.arguments.should eq({"name" => ["foo", "bar", "baz", "bat"]})
  end

  def test_array_option : Nil
    input = ACON::Input::ARGV.new ["--name=foo", "--name=bar", "--name=baz"]
    input.bind ACON::Input::Definition.new ACON::Input::Option.new "name", value_mode: ACON::Input::Option::Value[:optional, :is_array]
    input.options.should eq({"name" => ["foo", "bar", "baz"]})

    input = ACON::Input::ARGV.new ["--name", "foo", "--name", "bar", "--name", "baz"]
    input.bind ACON::Input::Definition.new ACON::Input::Option.new "name", value_mode: ACON::Input::Option::Value[:optional, :is_array]
    input.options.should eq({"name" => ["foo", "bar", "baz"]})

    input = ACON::Input::ARGV.new ["--name=foo", "--name=bar", "--name="]
    input.bind ACON::Input::Definition.new ACON::Input::Option.new "name", value_mode: ACON::Input::Option::Value[:optional, :is_array]
    input.options.should eq({"name" => ["foo", "bar", ""]})

    input = ACON::Input::ARGV.new ["--name=foo", "--name=bar", "--name", "--anotherOption"]
    input.bind ACON::Input::Definition.new(
      ACON::Input::Option.new("name", value_mode: ACON::Input::Option::Value[:optional, :is_array]),
      ACON::Input::Option.new("anotherOption", value_mode: :none),
    )
    input.options.should eq({"name" => ["foo", "bar", nil], "anotherOption" => true})
  end

  def test_parse_negative_number_after_double_dash : Nil
    input = ACON::Input::ARGV.new ["--", "-1"]
    input.bind ACON::Input::Definition.new ACON::Input::Argument.new "number"
    input.arguments.should eq({"number" => "-1"})

    input = ACON::Input::ARGV.new ["-f", "bar", "--", "-1"]
    input.bind ACON::Input::Definition.new(
      ACON::Input::Argument.new("number"),
      ACON::Input::Option.new("foo", "f", :optional),
    )

    input.options.should eq({"foo" => "bar"})
    input.arguments.should eq({"number" => "-1"})
  end

  def test_parse_empty_string_argument : Nil
    input = ACON::Input::ARGV.new ["-f", "bar", ""]
    input.bind ACON::Input::Definition.new(
      ACON::Input::Argument.new("empty"),
      ACON::Input::Option.new("foo", "f", :optional),
    )

    input.options.should eq({"foo" => "bar"})
    input.arguments.should eq({"empty" => ""})
  end

  @[DataProvider("parse_options_provider")]
  def test_parse_options(input_args : Array(String), options : Array(ACON::Input::Option | ACON::Input::Argument), expected : Hash) : Nil
    input = ACON::Input::ARGV.new input_args
    input.bind ACON::Input::Definition.new options

    input.options.should eq expected
  end

  def parse_options_provider : Hash
    {
      "long options without a value" => {
        ["--foo"],
        [ACON::Input::Option.new("foo")],
        {"foo" => true},
      },
      "long options with a required value (with a = separator)" => {
        ["--foo=bar"],
        [ACON::Input::Option.new("foo", "f", :required)],
        {"foo" => "bar"},
      },
      "long options with a required value (with a space separator)" => {
        ["--foo", "bar"],
        [ACON::Input::Option.new("foo", "f", :required)],
        {"foo" => "bar"},
      },
      "long options with optional value which is empty (with a = separator) as empty string" => {
        ["--foo="],
        [ACON::Input::Option.new("foo", "f", :optional)],
        {"foo" => ""},
      },
      "long options with optional value without value specified or an empty string (with a = separator) followed by an argument as empty string" => {
        ["--foo=", "bar"],
        [ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Argument.new("name", :required)],
        {"foo" => ""},
      },
      "long options with optional value which is empty (with a = separator) preceded by an argument" => {
        ["bar", "--foo"],
        [ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Argument.new("name", :required)],
        {"foo" => nil},
      },
      "long options with optional value which is empty as empty string even followed by an argument" => {
        ["--foo", "", "bar"],
        [ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Argument.new("name", :required)],
        {"foo" => ""},
      },
      "long options with optional value specified with no separator and no value as nil" => {
        ["--foo"],
        [ACON::Input::Option.new("foo", "f", :optional)],
        {"foo" => nil},
      },
      "short options without a value" => {
        ["-f"],
        [ACON::Input::Option.new("foo", "f")],
        {"foo" => true},
      },
      "short options with a required value (with no separator)" => {
        ["-fbar"],
        [ACON::Input::Option.new("foo", "f", :required)],
        {"foo" => "bar"},
      },
      "short options with a required value (with a space separator)" => {
        ["-f", "bar"],
        [ACON::Input::Option.new("foo", "f", :required)],
        {"foo" => "bar"},
      },
      "short options with an optional empty value" => {
        ["-f", ""],
        [ACON::Input::Option.new("foo", "f", :optional)],
        {"foo" => ""},
      },
      "short options with an optional empty value followed by an argument" => {
        ["-f", "", "foo"],
        [ACON::Input::Argument.new("name"), ACON::Input::Option.new("foo", "f", :optional)],
        {"foo" => ""},
      },
      "short options with an optional empty value followed by an option" => {
        ["-f", "", "-b"],
        [ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Option.new("bar", "b")],
        {"foo" => "", "bar" => true},
      },
      "short options with an optional value which is not present" => {
        ["-f", "-b", "foo"],
        [ACON::Input::Argument.new("name"), ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Option.new("bar", "b")],
        {"foo" => nil, "bar" => true},
      },
      "short options when they are aggregated as a single one" => {
        ["-fb"],
        [ACON::Input::Option.new("foo", "f"), ACON::Input::Option.new("bar", "b")],
        {"foo" => true, "bar" => true},
      },
      "short options when they are aggregated as a single one and the last one has a required value" => {
        ["-fb", "bar"],
        [ACON::Input::Option.new("foo", "f"), ACON::Input::Option.new("bar", "b", :required)],
        {"foo" => true, "bar" => "bar"},
      },
      "short options when they are aggregated as a single one and the last one has an optional value" => {
        ["-fb", "bar"],
        [ACON::Input::Option.new("foo", "f"), ACON::Input::Option.new("bar", "b", :optional)],
        {"foo" => true, "bar" => "bar"},
      },
      "short options when they are aggregated as a single one and the last one has an optional value with no separator" => {
        ["-fbbar"],
        [ACON::Input::Option.new("foo", "f"), ACON::Input::Option.new("bar", "b", :optional)],
        {"foo" => true, "bar" => "bar"},
      },
      "short options when they are aggregated as a single one and one of them takes a value" => {
        ["-fbbar"],
        [ACON::Input::Option.new("foo", "f", :optional), ACON::Input::Option.new("bar", "b", :optional)],
        {"foo" => "bbar", "bar" => nil},
      },
    }
  end

  @[DataProvider("parse_options_negatable_provider")]
  def test_parse_options_negatble(input_args : Array(String), options : Array(ACON::Input::Option | ACON::Input::Argument), expected : Hash) : Nil
    input = ACON::Input::ARGV.new input_args
    input.bind ACON::Input::Definition.new options

    input.options.should eq expected
  end

  def parse_options_negatable_provider : Hash
    {
      "long options without a value - negatable" => {
        ["--foo"],
        [ACON::Input::Option.new("foo", value_mode: :negatable)],
        {"foo" => true},
      },
      "long options without a value - no value negatable" => {
        ["--foo"],
        [ACON::Input::Option.new("foo", value_mode: ACON::Input::Option::Value[:none, :negatable])],
        {"foo" => true},
      },
      "negated long options without a value - negatable" => {
        ["--no-foo"],
        [ACON::Input::Option.new("foo", value_mode: :negatable)],
        {"foo" => false},
      },
      "negated long options without a value - no value negatable" => {
        ["--no-foo"],
        [ACON::Input::Option.new("foo", value_mode: ACON::Input::Option::Value[:none, :negatable])],
        {"foo" => false},
      },
      "missing negated option uses default - negatable" => {
        [] of String,
        [ACON::Input::Option.new("foo", value_mode: :negatable)],
        {"foo" => nil},
      },
      "missing negated option uses default - no value negatable" => {
        [] of String,
        [ACON::Input::Option.new("foo", value_mode: ACON::Input::Option::Value[:none, :negatable])],
        {"foo" => nil},
      },
      "missing negated option uses default - bool default" => {
        [] of String,
        [ACON::Input::Option.new("foo", value_mode: :negatable, default: false)],
        {"foo" => false},
      },
    }
  end

  def test_to_s : Nil
    input = ACON::Input::ARGV.new "-b", "bar"
    input.to_s.should eq "-b bar"
  end

  def test_to_s_complex : Nil
    input = ACON::Input::ARGV.new "-f", "--bar=foo", "a b c d", "A\nB'C"

    {% if flag? :windows %}
      input.to_s.should eq "-f --bar=foo \"a b c d\" A\nB'C"
    {% else %}
      input.to_s.should eq "-f --bar=foo 'a b c d' 'A\nB'\"'\"'C'"
    {% end %}
  end
end
