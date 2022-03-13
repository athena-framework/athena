require "spec"
require "../src/athena-validator"
require "../src/spec"

ASPEC.run_all

class MockConstraint < AVD::Constraint
  def validated_by : AVD::ConstraintValidator.class
    MockConstraintValidator
  end
end

class MockConstraintValidator < AVD::ConstraintValidator; end

class MockServiceConstraintValidator < AVD::ServiceConstraintValidator; end

class CustomConstraint < AVD::Constraint
  @@error_names = {
    "abc123" => "FAKE_ERROR",
  }

  class Validator < Athena::Validator::ConstraintValidator
    def validate(value : _, constraint : CustomConstraint) : Nil
    end
  end
end

def get_violation(message : String, *, invalid_value : _ = nil, root : _ = nil, property_path : String = "property_path", code : String? = nil) : AVD::Violation::ConstraintViolation
  AVD::Violation::ConstraintViolation.new message, message, Hash(String, String).new, root, property_path, AVD::ValueContainer.new(invalid_value), code: code
end
