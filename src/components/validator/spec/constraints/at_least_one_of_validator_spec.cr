require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::AtLeastOneOf

struct AtLeastOneOfValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def valid_combinations : Tuple
    {
      {"athena", [AVD::Constraints::Length.new(range: (10..)), AVD::Constraints::EqualTo.new(value: "athena")]},
      {150, [AVD::Constraints::Range.new(range: (10..20)), AVD::Constraints::GreaterThanOrEqual.new(value: 100)]},
      {[1, 3, 5], [AVD::Constraints::Count.new(range: (5..)), AVD::Constraints::Unique.new]},
    }
  end

  @[DataProvider("valid_combinations")]
  def test_valid_combinations(value : _, constraints : Array(AVD::Constraint)) : Nil
    constraints.each_with_index do |constraint, idx|
      self.expect_violation_at idx, value, constraint
    end

    self.validator.validate value, self.new_constraint constraints: constraints
    self.assert_no_violation
  end

  def invalid_combinations : Tuple
    {
      {"athenaa", [AVD::Constraints::Length.new(range: (10..)), AVD::Constraints::EqualTo.new(value: "athena")]},
      {50, [AVD::Constraints::Range.new(range: (10..20)), AVD::Constraints::GreaterThanOrEqual.new(value: 100)]},
      {[1, 3, 3], [AVD::Constraints::Count.new(range: (5..)), AVD::Constraints::Unique.new]},
    }
  end

  @[DataProvider("invalid_combinations")]
  def test_invalid_combinations_default_message(value : _, constraints : Array(AVD::Constraint)) : Nil
    constraint = self.new_constraint constraints: constraints

    message = [constraint.message]

    constraints.each_with_index do |c, idx|
      message << " [#{idx + 1}] #{self.expect_violation_at(idx, value, c).first.message}"
    end

    self.validator.validate value, constraint

    self
      .build_violation(message.join, CONSTRAINT::AT_LEAST_ONE_OF_ERROR)
      .assert_violation
  end

  @[DataProvider("invalid_combinations")]
  def test_invalid_combinations_custom_message(value : _, constraints : Array(AVD::Constraint)) : Nil
    constraints.each_with_index do |constraint, idx|
      self.expect_violation_at idx, value, constraint
    end

    self.validator.validate value, self.new_constraint constraints: constraints, message: "my_message", include_internal_messages: false

    self
      .build_violation("my_message", CONSTRAINT::AT_LEAST_ONE_OF_ERROR)
      .assert_violation
  end

  def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
