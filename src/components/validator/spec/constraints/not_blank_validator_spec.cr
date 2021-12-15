require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::NotBlank

struct NotBlankValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  @[DataProvider("valid_values")]
  def test_valid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  def valid_values : NamedTuple
    {
      string: {"foo"},
      array:  {[1, 2, 3]},
      bool:   {true},
    }
  end

  def test_blank_is_invalid
    self.validator.validate "", self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::IS_BLANK_ERROR, ""
  end

  def test_false_is_invalid
    self.validator.validate false, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::IS_BLANK_ERROR, false
  end

  def test_empty_array_is_invalid
    self.validator.validate [] of String, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::IS_BLANK_ERROR, [] of String
  end

  def test_allow_nil_true
    self.validator.validate nil, self.new_constraint message: "my_message", allow_nil: true
    self.assert_no_violation
  end

  def test_allow_nil_false
    self.validator.validate nil, self.new_constraint message: "my_message", allow_nil: false
    self.assert_violation "my_message", CONSTRAINT::IS_BLANK_ERROR, nil
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
