require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::All

struct AllValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint constraints: AVD::Constraints::NotBlank.new
    self.assert_no_violation
  end

  def test_raises_if_value_is_not_hash_or_indexable : Nil
    expect_raises AVD::Exceptions::UnexpectedValueError, "Expected argument of type 'Hash | Indexable', 'String' given." do
      self.validator.validate "FOO", self.new_constraint constraints: AVD::Constraints::NotBlank.new
    end
  end

  def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
