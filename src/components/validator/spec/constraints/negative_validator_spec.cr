require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Negative

struct NegativeValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_valid_value : Nil
    self.validator.validate -1, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("invalid_values")]
  def test_invalid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self
      .build_violation("my_message", CONSTRAINT::TOO_HIGH_ERROR, value)
      .add_parameter("{{ compared_value }}", "0")
      .add_parameter("{{ compared_value_type }}", "Int32")
      .assert_violation
  end

  def invalid_values : Tuple
    {
      {0},
      {1},
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
