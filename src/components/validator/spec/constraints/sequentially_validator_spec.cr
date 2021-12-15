require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Sequentially

struct SequentiallyValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_walk_though_constraints : Nil
    self.validator.validate 6, self.new_constraint constraints: [AVD::Constraints::Range.new(4..), AVD::Constraints::Positive.new]
    self.assert_no_violation
  end

  def ptest_stop_at_first_constraint_with_violation : Nil
    self.validator.validate nil, self.new_constraint constraints: [AVD::Constraints::NotBlank.new, AVD::Constraints::NotNil.new]

    # TODO: Determine how to test this given it depends on an actual validator instance
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
