require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Callback

struct CallbackValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_callback : Nil
    constraint = CONSTRAINT.with_callback(payload: {"foo" => "bar"}) do |value, context, payload|
      value.should eq 123
      payload.should eq({"foo" => "bar"})

      context.add_violation("my_message")
    end

    self.validator.validate 123, constraint
    self.assert_violation "my_message"
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
