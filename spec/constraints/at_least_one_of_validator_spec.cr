require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::AtLeastOneOf

struct AtLeastOneOfValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def valid_combinations : Tuple
    {
      {"athena", [AVD::Constraints::Size.new(range: (10..)), AVD::Constraints::EqualTo.new(value: "athena")]},
      {150, [AVD::Constraints::Range.new(range: (10..20)), AVD::Constraints::GreaterThanOrEqual.new(value: 100)]},
      {[1, 3, 5], [AVD::Constraints::Size.new(range: (5..)), AVD::Constraints::Unique.new]},
    }
  end

  @[DataProvider("valid_combinations")]
  def test_valid_combinations(value : _, constraints : Array(AVD::Constraint)) : Nil
    self.validator.validate value, self.new_constraint(constraints: constraints)
    self.assert_no_violation
  end

  def invalid_combinations : Tuple
    {
      {"athenaa", [AVD::Constraints::Size.new(range: (10..)), AVD::Constraints::EqualTo.new(value: "athena")]},
      {50, [AVD::Constraints::Range.new(range: (10..20)), AVD::Constraints::GreaterThanOrEqual.new(value: 100)]},
      {[1, 3, 3], [AVD::Constraints::Size.new(range: (5..)), AVD::Constraints::Unique.new]},
    }
  end

  @[DataProvider("invalid_combinations")]
  def ptest_invalid_combinations(value : _, constraints : Array(AVD::Constraint)) : Nil
    constraint = self.new_constraint(constraints: constraints)
    self.validator.validate value, constraint

    # TODO: Determine how to test this given it depends on an actual validator instance
  end

  def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
