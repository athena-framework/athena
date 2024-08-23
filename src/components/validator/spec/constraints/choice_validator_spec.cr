require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Choice

struct ChoiceValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_requires_enumerable_if_multiple_is_true : Nil
    expect_raises AVD::Exception::UnexpectedValueError, "Enumerable" do
      self.validator.validate "foo", self.new_constraint choices: ["foo", "bar"], multiple: true
    end
  end

  def test_requires_enumerable_if_multiple_is_false : Nil
    expect_raises AVD::Exception::UnexpectedValueError, "Enumerable" do
      self.validator.validate [1, 2], self.new_constraint choices: ["foo", "bar"], multiple: false
    end
  end

  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint choices: ["foo", "bar"]
    self.assert_no_violation
  end

  def test_valid_choice : Nil
    self.validator.validate "bar", self.new_constraint choices: ["foo", "bar"]
    self.assert_no_violation
  end

  def test_multiple_choices : Nil
    self.validator.validate ["foo", "bar"], self.new_constraint choices: ["foo", "bar"], multiple: true
    self.assert_no_violation
  end

  def test_invalid_choice : Nil
    self.validator.validate "baz", self.new_constraint choices: ["foo", "bar"], message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NO_SUCH_CHOICE_ERROR, "baz")
      .add_parameter("{{ choices }}", ["foo", "bar"])
      .assert_violation
  end

  def test_invalid_choice_empty_choices_array : Nil
    self.validator.validate "baz", self.new_constraint choices: [] of String, message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NO_SUCH_CHOICE_ERROR, "baz")
      .add_parameter("{{ choices }}", [] of String)
      .assert_violation
  end

  def test_invalid_choices_multiple : Nil
    self.validator.validate ["foo", "baz"], self.new_constraint choices: ["foo", "bar"], multiple: true, multiple_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NO_SUCH_CHOICE_ERROR, "baz")
      .add_parameter("{{ choices }}", ["foo", "bar"])
      .invalid_value("baz")
      .assert_violation
  end

  def test_invalid_choices_too_few : Nil
    value = ["foo"]

    self.value = value

    self.validator.validate value, self.new_constraint choices: ["foo", "bar", "moo", "maa"], multiple: true, range: (2..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_FEW_ERROR, value)
      .add_parameter("{{ limit }}", 2)
      .add_parameter("{{ choices }}", ["foo", "bar", "moo", "maa"])
      .invalid_value(value)
      .plural(2)
      .assert_violation
  end

  def test_invalid_choices_too_many : Nil
    value = ["foo", "bar", "moo"]

    self.value = value

    self.validator.validate value, self.new_constraint choices: ["foo", "bar", "moo", "maa"], multiple: true, range: (..2), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_MANY_ERROR, value)
      .add_parameter("{{ limit }}", 2)
      .add_parameter("{{ choices }}", ["foo", "bar", "moo", "maa"])
      .invalid_value(value)
      .plural(2)
      .assert_violation
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
