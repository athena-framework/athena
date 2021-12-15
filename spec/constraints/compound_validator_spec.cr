require "../spec_helper"

private class DummyCompoundConstraint < AVD::Constraints::Compound
  def constraints : Array(AVD::Constraint)
    [
      AVD::Constraints::NotBlank.new,
      AVD::Constraints::Size.new (..3),
    ]
  end
end

struct CompoundValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_valid_value : Nil
    self.validator.validate "foo", DummyCompoundConstraint.new
    self.assert_no_violation
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    AVD::Constraints::Compound::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    DummyCompoundConstraint
  end
end
