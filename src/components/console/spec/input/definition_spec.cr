require "../spec_helper"

struct InputDefinitionTest < ASPEC::TestCase
  getter arg_foo : ACON::Input::Argument { ACON::Input::Argument.new "foo" }
  getter arg_foo1 : ACON::Input::Argument { ACON::Input::Argument.new "foo" }
  getter arg_foo2 : ACON::Input::Argument { ACON::Input::Argument.new "foo2", :required }
  getter arg_bar : ACON::Input::Argument { ACON::Input::Argument.new "bar" }

  getter opt_foo : ACON::Input::Option { ACON::Input::Option.new "foo", "f" }
  getter opt_foo1 : ACON::Input::Option { ACON::Input::Option.new "foobar", "f" }
  getter opt_foo2 : ACON::Input::Option { ACON::Input::Option.new "foo", "p" }
  getter opt_bar : ACON::Input::Option { ACON::Input::Option.new "bar", "b" }
  getter opt_multi : ACON::Input::Option { ACON::Input::Option.new "multi", "m|mm|mmm" }

  def test_new_arguments : Nil
    definition = ACON::Input::Definition.new
    definition.arguments.should be_empty

    # Splat
    definition = ACON::Input::Definition.new self.arg_foo, self.arg_bar
    definition.arguments.should eq({"foo" => self.arg_foo, "bar" => self.arg_bar})

    # Array
    definition = ACON::Input::Definition.new [self.arg_foo, self.arg_bar]
    definition.arguments.should eq({"foo" => self.arg_foo, "bar" => self.arg_bar})

    # Hash
    definition = ACON::Input::Definition.new({"foo" => self.arg_foo, "bar" => self.arg_bar})
    definition.arguments.should eq({"foo" => self.arg_foo, "bar" => self.arg_bar})
  end

  def test_new_options : Nil
    definition = ACON::Input::Definition.new
    definition.options.should be_empty

    # Splat
    definition = ACON::Input::Definition.new self.opt_foo, self.opt_bar
    definition.options.should eq({"foo" => self.opt_foo, "bar" => self.opt_bar})

    # Array
    definition = ACON::Input::Definition.new [self.opt_foo, self.opt_bar]
    definition.options.should eq({"foo" => self.opt_foo, "bar" => self.opt_bar})

    # Hash
    definition = ACON::Input::Definition.new({"foo" => self.opt_foo, "bar" => self.opt_bar})
    definition.options.should eq({"foo" => self.opt_foo, "bar" => self.opt_bar})
  end

  def test_set_arguments : Nil
    definition = ACON::Input::Definition.new

    definition.arguments = [self.arg_foo]
    definition.arguments.should eq({"foo" => self.arg_foo})

    definition.arguments = [self.arg_bar]
    definition.arguments.should eq({"bar" => self.arg_bar})
  end

  def test_add_arguments : Nil
    definition = ACON::Input::Definition.new

    definition << [self.arg_foo]
    definition.arguments.should eq({"foo" => self.arg_foo})

    definition << [self.arg_bar]
    definition.arguments.should eq({"foo" => self.arg_foo, "bar" => self.arg_bar})
  end

  def test_add_argument : Nil
    definition = ACON::Input::Definition.new

    definition << self.arg_foo
    definition.arguments.should eq({"foo" => self.arg_foo})

    definition << self.arg_bar
    definition.arguments.should eq({"foo" => self.arg_foo, "bar" => self.arg_bar})
  end

  def test_add_argument_must_have_unique_names : Nil
    definition = ACON::Input::Definition.new self.arg_foo

    expect_raises ACON::Exception::Logic, "An argument with the name 'foo' already exists." do
      definition << self.arg_foo
    end
  end

  def test_add_argument_array_argument_must_be_last : Nil
    definition = ACON::Input::Definition.new ACON::Input::Argument.new "foo_array", :is_array

    expect_raises ACON::Exception::Logic, "Cannot add a required argument 'foo' after Array argument 'foo_array'." do
      definition << ACON::Input::Argument.new "foo"
    end
  end

  def test_add_argument_required_argument_cannot_follow_optional : Nil
    definition = ACON::Input::Definition.new self.arg_foo

    expect_raises ACON::Exception::Logic, "Cannot add required argument 'foo2' after the optional argument 'foo'." do
      definition << self.arg_foo2
    end
  end

  def test_argument : Nil
    definition = ACON::Input::Definition.new self.arg_foo

    definition.argument("foo").should be self.arg_foo
    definition.argument(0).should be self.arg_foo
  end

  def test_argument_missing : Nil
    definition = ACON::Input::Definition.new self.arg_foo

    expect_raises ACON::Exception::InvalidArgument, "The argument 'bar' does not exist." do
      definition.argument "bar"
    end
  end

  def test_has_argument : Nil
    definition = ACON::Input::Definition.new self.arg_foo

    definition.has_argument?("foo").should be_true
    definition.has_argument?(0).should be_true
    definition.has_argument?("bar").should be_false
    definition.has_argument?(1).should be_false
  end

  def test_required_argument_count : Nil
    definition = ACON::Input::Definition.new

    definition << self.arg_foo2
    definition.required_argument_count.should eq 1

    definition << self.arg_foo
    definition.required_argument_count.should eq 1
  end

  def test_argument_count : Nil
    definition = ACON::Input::Definition.new

    definition << self.arg_foo2
    definition.argument_count.should eq 1

    definition << self.arg_foo
    definition.argument_count.should eq 2

    definition << ACON::Input::Argument.new "foo_array", :is_array
    definition.argument_count.should eq Int32::MAX
  end

  def test_argument_defaults : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Argument.new("foo1", :optional),
      ACON::Input::Argument.new("foo2", :optional, "", "default"),
      ACON::Input::Argument.new("foo3", ACON::Input::Argument::Mode[:optional, :is_array]),
    )

    definition.argument_defaults.should eq({"foo1" => nil, "foo2" => "default", "foo3" => [] of String})

    definition = ACON::Input::Definition.new(
      ACON::Input::Argument.new("foo4", ACON::Input::Argument::Mode[:optional, :is_array], default: ["1", "2"]),
    )

    definition.argument_defaults.should eq({"foo4" => ["1", "2"]})
  end

  def test_set_options : Nil
    definition = ACON::Input::Definition.new

    definition.options = [self.opt_foo]
    definition.options.should eq({"foo" => self.opt_foo})

    definition.options = [self.opt_bar]
    definition.options.should eq({"bar" => self.opt_bar})
  end

  def test_set_options_clears_options : Nil
    definition = ACON::Input::Definition.new [self.opt_foo]
    definition.options = [self.opt_bar]

    expect_raises ACON::Exception::InvalidArgument, "The '-f' option does not exist." do
      definition.option_for_shortcut "f"
    end
  end

  def test_add_options : Nil
    definition = ACON::Input::Definition.new

    definition << [self.opt_foo]
    definition.options.should eq({"foo" => self.opt_foo})

    definition << [self.opt_bar]
    definition.options.should eq({"foo" => self.opt_foo, "bar" => self.opt_bar})
  end

  def test_add_option : Nil
    definition = ACON::Input::Definition.new

    definition << self.opt_foo
    definition.options.should eq({"foo" => self.opt_foo})

    definition << self.opt_bar
    definition.options.should eq({"foo" => self.opt_foo, "bar" => self.opt_bar})
  end

  def test_add_option_must_have_unique_names : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    expect_raises ACON::Exception::Logic, "An option named 'foo' already exists." do
      definition << self.opt_foo2
    end
  end

  def test_add_option_duplicate_negated : Nil
    definition = ACON::Input::Definition.new ACON::Input::Option.new "no-foo"

    expect_raises ACON::Exception::Logic, "An option named 'no-foo' already exists." do
      definition << ACON::Input::Option.new "foo", value_mode: :negatable
    end
  end

  def test_add_option_duplicate_negated_reverse_option : Nil
    definition = ACON::Input::Definition.new ACON::Input::Option.new "foo", value_mode: :negatable

    expect_raises ACON::Exception::Logic, "An option named 'no-foo' already exists." do
      definition << ACON::Input::Option.new "no-foo"
    end
  end

  def test_add_option_duplicate_shortcut : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    expect_raises ACON::Exception::Logic, "An option with shortcut 'f' already exists." do
      definition << self.opt_foo1
    end
  end

  def test_option : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    definition.option("foo").should be self.opt_foo
    definition.option(0).should be self.opt_foo
  end

  def test_option_missing : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    expect_raises ACON::Exception::InvalidArgument, "The '--bar' option does not exist." do
      definition.option "bar"
    end
  end

  def test_has_option : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    definition.has_option?("foo").should be_true
    definition.has_option?(0).should be_true
    definition.has_option?("bar").should be_false
    definition.has_option?(1).should be_false
  end

  def test_has_shortcut : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    definition.has_shortcut?("f").should be_true
    definition.has_shortcut?("p").should be_false
  end

  def test_option_for_shortcut : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    definition.option_for_shortcut("f").should be self.opt_foo
  end

  def test_option_for_shortcut_multi : Nil
    definition = ACON::Input::Definition.new self.opt_multi

    definition.option_for_shortcut("m").should be self.opt_multi
    definition.option_for_shortcut("mmm").should be self.opt_multi
  end

  def test_option_for_shortcut_invalid : Nil
    definition = ACON::Input::Definition.new self.opt_foo

    expect_raises ACON::Exception::InvalidArgument, "The '-l' option does not exist." do
      definition.option_for_shortcut "l"
    end
  end

  def test_option_defaults : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Option.new("foo1", value_mode: :none),
      ACON::Input::Option.new("foo2", value_mode: :required),
      ACON::Input::Option.new("foo3", value_mode: :required, default: "default"),
      ACON::Input::Option.new("foo4", value_mode: :optional),
      ACON::Input::Option.new("foo5", value_mode: :optional, default: "default"),
      ACON::Input::Option.new("foo6", value_mode: ACON::Input::Option::Value[:optional, :is_array]),
      ACON::Input::Option.new("foo7", value_mode: ACON::Input::Option::Value[:optional, :is_array], default: ["1", "2"]),
    )

    definition.option_defaults.should eq({
      "foo1" => false,
      "foo2" => nil,
      "foo3" => "default",
      "foo4" => nil,
      "foo5" => "default",
      "foo6" => [] of String,
      "foo7" => ["1", "2"],
    })
  end

  def test_negation_to_name : Nil
    definition = ACON::Input::Definition.new ACON::Input::Option.new "foo", value_mode: :negatable
    definition.negation_to_name("no-foo").should eq "foo"
  end

  def test_negation_to_name_invalid : Nil
    definition = ACON::Input::Definition.new ACON::Input::Option.new "foo", value_mode: :negatable

    expect_raises ACON::Exception::InvalidArgument, "The '--no-bar' option does not exist." do
      definition.negation_to_name "no-bar"
    end
  end

  @[DataProvider("synopsis_provider")]
  def test_synopsis(definition : ACON::Input::Definition, expected : String) : Nil
    definition.synopsis.should eq expected
  end

  def synopsis_provider : Hash
    {
      "puts optional options in square brackets" => {ACON::Input::Definition.new(ACON::Input::Option.new("foo")), "[--foo]"},
      "separates shortcuts with a pipe"          => {ACON::Input::Definition.new(ACON::Input::Option.new("foo", "f")), "[-f|--foo]"},
      "uses shortcut as value placeholder"       => {ACON::Input::Definition.new(ACON::Input::Option.new("foo", "f", :required)), "[-f|--foo FOO]"},
      "puts optional values in square brackets"  => {ACON::Input::Definition.new(ACON::Input::Option.new("foo", "f", :optional)), "[-f|--foo [FOO]]"},

      "puts arguments in angle brackets"              => {ACON::Input::Definition.new(ACON::Input::Argument.new("foo", :required)), "<foo>"},
      "puts optional arguments square brackets"       => {ACON::Input::Definition.new(ACON::Input::Argument.new("foo", :optional)), "[<foo>]"},
      "chains optional arguments inside brackets"     => {ACON::Input::Definition.new(ACON::Input::Argument.new("foo"), ACON::Input::Argument.new("bar")), "[<foo> [<bar>]]"},
      "uses an ellipsis for array arguments"          => {ACON::Input::Definition.new(ACON::Input::Argument.new("foo", :is_array)), "[<foo>...]"},
      "uses an ellipsis for required array arguments" => {ACON::Input::Definition.new(ACON::Input::Argument.new("foo", ACON::Input::Argument::Mode[:required, :is_array])), "<foo>..."},

      "puts [--] between options and arguments" => {ACON::Input::Definition.new(ACON::Input::Option.new("foo"), ACON::Input::Argument.new("foo", :required)), "[--foo] [--] <foo>"},
    }
  end

  def test_synopsis_short : Nil
    definition = ACON::Input::Definition.new(
      ACON::Input::Option.new("foo"),
      ACON::Input::Option.new("bar"),
      ACON::Input::Argument.new("baz"),
    )

    definition.synopsis(true).should eq "[options] [--] [<baz>]"
  end
end
