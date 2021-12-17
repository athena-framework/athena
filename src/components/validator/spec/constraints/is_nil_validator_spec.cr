require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::IsNil

struct IsNilValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("invalid_values")]
  def test_invalid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::NOT_NIL_ERROR, value
  end

  def invalid_values : Tuple
    {
      {"foobar"},
      {0},
      {false},
      {true},
      {""},
      {Time.utc},
      {[] of Int32},
      {Pointer(Void).null},
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
