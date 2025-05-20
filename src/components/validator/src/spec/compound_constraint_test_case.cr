# The `AVD::Constraints::Compound` constraint allows grouping other constraints into a single reusable constraint.
# Such as for defining requirements of a user's password.
#
# This type may be used to more easily test compound constraints.
# For example, using the `AVD::Constraints::ValidPassword` constraint in the usage docs for the `Compound` constraint:
#
# ```
# # The generic should be set to the type(s) that the compound constraint supports.
# struct ValidPasswordTest < AVD::Spec::CompoundConstraintTestCase(String?)
#   protected def create_compound : AVD::Constraints::Compound
#     AVD::Constraints::ValidPassword.new
#   end
#
#   def test_valid_password : Nil
#     self.validate_value "1VeryStr0ngP4$$wOrD"
#
#     self.assert_no_violation
#   end
#
#   @[TestWith(
#     nil: {nil, AVD::Constraints::NotBlank.new},
#     too_short: {"123", AVD::Constraints::Size.new(12..)},
#     letter_first: {"abc12345qwerty", AVD::Constraints::Regex.new(/^\d.*/)},
#   )]
#   def test_invalid_password(password : String?, expected_failing_constraint : AVD::Constraint) : Nil
#     self.validate_value password
#
#     self.assert_violations_raised_by_compound expected_failing_constraint
#   end
# end
# ```
abstract struct Athena::Validator::Spec::CompoundConstraintTestCase(T) < ASPEC::TestCase
  @validator : AVD::Validator::ValidatorInterface
  @violation_list : Array(AVD::Violation::ConstraintViolationListInterface)? = nil
  @context : AVD::ExecutionContextInterface
  @root : String

  private getter! validated_value : AVD::ValueContainer(T)

  private class MockCompoundValidator < AVD::Constraints::Compound
    def initialize(@tested_constraints : Array(AVD::Constraint))
      super()
    end

    def constraints : AVD::Constraints::Composite::Type
      @tested_constraints
    end
  end

  protected def initialize
    @root = "root"
    @validator = validator = create_validator
    @context = create_context validator
  end

  # :showdoc:
  #
  # Returns the compound constraint instance to be tested.
  protected abstract def create_compound : AVD::Constraints::Compound

  # :showdoc:
  #
  # Asserts that each of the provided *constraints* were properly raised.
  protected def assert_violations_raised_by_compound(*constraints : AVD::Constraint) : Nil
    validator = AVD::Constraints::Compound::Validator.new
    context = self.create_context
    validator.context = context

    validator.validate self.validated_value.value, MockCompoundValidator.new(constraints.to_a.map(&.as(AVD::Constraint)))

    expected_violations = context.violations

    expected_violations.should_not be_empty, failure_message: "Expected at least one violation for constraint(s): '#{constraints.join(", ", &.class)}', got none."

    failed_to_assert_violations = [] of AVD::Violation::ConstraintViolationInterface

    @context.violations.each_with_index do |violation, idx|
      if violation != expected_violations[idx]?
        failed_to_assert_violations << violation
      end
    end

    failed_to_assert_violations.should be_empty, failure_message: "Expected violation(s) for constraint(s) '#{failed_to_assert_violations.join(", ", &.constraint.class)}' to be raised by compound."
  end

  # :showdoc:
  #
  # Validates the provided *value*, populating the data required for further assertions.
  protected def validate_value(value : T) : Nil
    @validated_value = AVD::ValueContainer(T).new(value)
    @validator.in_context(@context).validate(value, self.create_compound)
  end

  # :showdoc:
  #
  # Asserts there are *count* violations after calling `#validate_value`.
  protected def assert_violation_count(count : Int) : Nil
    @context.violations.size.should eq count
  end

  # :showdoc:
  #
  # Asserts there are no violations after calling `#validate_value`.
  protected def assert_no_violation : Nil
    @context.violations.should be_empty
  end

  private def create_validator : AVD::Validator::ValidatorInterface
    AVD.validator
  end

  private def create_context(validator : AVD::Validator::ValidatorInterface? = nil) : AVD::ExecutionContextInterface
    AVD::ExecutionContext.new validator || create_validator, @root
  end
end
