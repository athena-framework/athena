require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::IsFalse

struct IsFalseValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_false_is_valid : Nil
    self.validator.validate false, self.new_constraint
    self.assert_no_violation
  end

  def test_true_is_invalid : Nil
    self.validator.validate true, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::NOT_FALSE_ERROR, true
  end

  def test_zero_is_invalid : Nil
    self.validator.validate 0, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::NOT_FALSE_ERROR, 0
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
