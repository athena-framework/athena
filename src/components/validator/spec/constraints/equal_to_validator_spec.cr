require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::EqualTo

struct EqualToValidatorTest < AVD::Spec::ComparisonConstraintValidatorTestCase
  def valid_comparisons : Tuple
    {
      {3, 3},
      {'a', 'a'},
      {"a", "a"},
      {Time.utc(2020, 4, 7), Time.utc(2020, 4, 7)},
      {nil, false},
    }
  end

  def invalid_comparisons : Tuple
    {
      {1, 3},
      {'b', 'a'},
      {"b", "a"},
      {Time.utc(2020, 4, 8), Time.utc(2020, 4, 7)},
    }
  end

  def error_code : String
    CONSTRAINT::NOT_EQUAL_ERROR
  end

  def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
