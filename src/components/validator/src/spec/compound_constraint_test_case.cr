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

  def initialize
    @root = "root"
    @validator = validator = create_validator
    @context = create_context validator
  end

  protected abstract def create_compound : AVD::Constraints::Compound

  def assert_violations_raised_by_compound(*constraints : AVD::Constraint) : Nil
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

  protected def validate_value(value : T) : Nil
    @validated_value = AVD::ValueContainer(T).new(value)
    @validator.in_context(@context).validate(value, self.create_compound)
  end

  protected def assert_violation_count(count : Int) : Nil
    @context.violations.size.should eq count
  end

  protected def assert_no_violation : Nil
    @context.violations.should be_empty
  end

  protected def create_validator : AVD::Validator::ValidatorInterface
    AVD.validator
  end

  protected def create_context(validator : AVD::Validator::ValidatorInterface? = nil) : AVD::ExecutionContextInterface
    AVD::ExecutionContext.new validator || create_validator, @root
  end
end
