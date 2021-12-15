require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Blank

struct BlankValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_blank_is_valid : Nil
    self.validator.validate "", self.new_constraint
    self.assert_no_violation
  end

  def test_blank_spaces_is_valid : Nil
    self.validator.validate "   ", self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("invalid_values")]
  def test_invalid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::NOT_BLANK_ERROR, value
  end

  def invalid_values : Tuple
    {
      {"foobar"},
      {0},
      {false},
      {1234},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
