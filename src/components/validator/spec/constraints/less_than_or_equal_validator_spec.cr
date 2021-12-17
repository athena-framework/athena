require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::LessThanOrEqual

struct LessThanOrEqualValidatorTest < AVD::Spec::ComparisonConstraintValidatorTestCase
  def valid_comparisons : Tuple
    {
      {2, 3},
      {0, 0_u8},
      {"a", "b"},
      {"22", "22"},
      {Time.utc(2020, 4, 6), Time.utc(2020, 4, 7)},
      {nil, false},
    }
  end

  def invalid_comparisons : Tuple
    {
      {3, 2},
      {"333", "22"},
      {Time.utc(2020, 4, 8), Time.utc(2020, 4, 7)},
    }
  end

  def test_invalid_type : Nil
    expect_raises AVD::Exceptions::UnexpectedValueError, "Expected argument of type 'Number | String | Time', 'Bool' given." do
      self.validator.validate false, new_constraint value: 50
    end
  end

  def error_code : String
    CONSTRAINT::TOO_HIGH_ERROR
  end

  def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
