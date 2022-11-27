require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Collection

abstract struct CollectionValidatorTestCase < AVD::Spec::ConstraintValidatorTestCase
  private abstract def prepare_test_data(contents : Hash)

  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint fields: {"foo" => AVD::Constraints::NotBlank.new}
    self.assert_no_violation
  end

  def test_valid_value : Nil
    constraint = AVD::Constraints::Range.new 4..

    data = self.prepare_test_data({"foo" => "foobar"})

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    self.validator.validate data, AVD::Constraints::Collection.new({"foo" => constraint})

    self.assert_no_violation
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
