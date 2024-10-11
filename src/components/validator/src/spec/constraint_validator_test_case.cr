# Test case designed to make testing `AVD::ConstraintValidatorInterface` easier.
#
# ### Example
#
# Using the spec from `AVD::Constraints::NotNil`:
#
# ```
# # Makes for a bit less typing when needing to reference the constraint.
# private alias CONSTRAINT = AVD::Constraints::NotNil
#
# # Define our test case inheriting from the abstract ConstraintValidatorTestCase.
# struct NotNilValidatorTest < AVD::Spec::ConstraintValidatorTestCase
#   @[DataProvider("valid_values")]
#   def test_valid_values(value : _) : Nil
#     # Validate the value against a new instance of the constraint.
#     self.validator.validate value, self.new_constraint
#
#     # Assert no violations were added to the context.
#     self.assert_no_violation
#   end
#
#   # Use data providers to reduce duplication.
#   def valid_values : NamedTuple
#     {
#       string:       {""},
#       bool_false:   {false},
#       bool_true:    {true},
#       zero:         {0},
#       null_pointer: {Pointer(Void).null},
#     }
#   end
#
#   def test_nil_is_invalid
#     # Validate an invalid value against a new instance of the constraint with a custom message.
#     self.validator.validate nil, self.new_constraint message: "my_message"
#
#     # Assert a violation with the expected message, code, and value parameter is added to the context.
#     self
#       .build_violation("my_message", CONSTRAINT::IS_NULL_ERROR, nil)
#       .assert_violation
#   end
#
#   # Implement some abstract defs to return the validator and constraint class.
#   private def create_validator : AVD::ConstraintValidatorInterface
#     CONSTRAINT::Validator.new
#   end
#
#   private def constraint_class : AVD::Constraint.class
#     CONSTRAINT
#   end
# end
# ```
#
# This type is an extension of `ASPEC::TestCase`, see that type for more information on this testing approach.
# This approach also allows using `ASPEC::TestCase::DataProvider`s for reducing duplication within your test.
abstract struct Athena::Validator::Spec::ConstraintValidatorTestCase < ASPEC::TestCase
  # Used to assert that a violation added via the `AVD::ConstraintValidatorInterface` was built as expected.
  #
  # NOTE: This type should not be instantiated directly, use `AVD::Spec::ConstraintValidatorTestCase#build_violation` instead.
  record Assertion, context : AVD::ExecutionContextInterface, message : String, constraint : AVD::Constraint do
    @parameters : Hash(String, String) = Hash(String, String).new
    @invalid_value : AVD::Container = AVD::ValueContainer.new("invalid_value")
    @property_path : String = "property.path"
    @plural : Int32? = nil
    @code : String? = nil
    @cause : String? = nil

    # Sets the `AVD::Violation::ConstraintViolationInterface#property_path` on the expected violation.
    #
    # Returns `self` for chaining.
    def at_path(@property_path : String) : self
      self
    end

    # Adds the provided *key* *value* pair to the expected violations' `AVD::Violation::ConstraintViolationInterface#parameters`.
    #
    # Returns `self` for chaining.
    def add_parameter(key : String, value : _) : self
      @parameters[key] = value.to_s

      self
    end

    # Sets the `AVD::Violation::ConstraintViolationInterface#invalid_value` on the expected violation.
    #
    # Returns `self` for chaining.
    def invalid_value(value : _) : self
      @invalid_value = AVD::ValueContainer.new value

      self
    end

    # Sets the `AVD::Violation::ConstraintViolationInterface#plural` on the expected violation.
    #
    # Returns `self` for chaining.
    def plural(@plural : Int32) : self
      self
    end

    # Sets the `AVD::Violation::ConstraintViolationInterface#code` on the expected violation.
    #
    # Returns `self` for chaining.
    def code(@code : String?) : self
      self
    end

    # Sets the `AVD::Violation::ConstraintViolationInterface#cause` on the expected violation.
    #
    # Returns `self` for chaining.
    def cause(@cause : String?) : self
      self
    end

    # Asserts that the violation added to the context equals the violation built via `self`.
    def assert_violation(*, file : String = __FILE__, line : Int32 = __LINE__) : Nil
      expected_violations = [self.get_violation] of AVD::Violation::ConstraintViolationInterface

      violations = @context.violations

      violations.size.should eq(1), failure_message: "Expected 1 violation, got #{violations.size}."

      expected_violations.each_with_index do |violation, idx|
        violations[idx].should eq(violation), file: file, line: line
      end
    end

    private def get_violation
      AVD::Violation::ConstraintViolation.new(
        @message,
        @message,
        @parameters,
        @context.root_container,
        @property_path,
        @invalid_value,
        @plural,
        @code,
        @constraint,
        @cause
      )
    end
  end

  # :nodoc:
  class AssertingContextualValidator
    include AVD::Validator::ContextualValidatorInterface

    record Expectation,
      value : String | Int32 | Nil,
      groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil,
      constraints : Proc(Array(AVD::Constraint) | AVD::Constraint | Nil, Nil),
      violation : AVD::Violation::ConstraintViolationInterface? = nil

    @context : AVD::ExecutionContextInterface

    @expect_no_validate = false
    @at_path_calls = -1
    @expected_at_path = [] of String?
    @validate_calls = -1
    @expected_validate = [] of Expectation?

    def initialize(@context : AVD::ExecutionContextInterface); end

    def at_path(path : String) : AVD::Validator::ContextualValidatorInterface
      @expect_no_validate.should be_false, failure_message: "No validation calls have been expected."

      unless expected_path = @expected_at_path[@at_path_calls += 1]?
        fail "Validation for property path '#{path}' was not expected."
      end

      @expected_at_path[@at_path_calls] = nil

      path.should eq expected_path

      self
    end

    def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      @expect_no_validate.should be_false, failure_message: "No validation calls have been expected."

      unless expectation = @expected_validate[@validate_calls += 1]?
        return self
      end
      @expected_validate[@validate_calls] = nil

      value.should eq expectation.value
      expectation.constraints.call constraints
      expectation.groups.should eq groups

      if v = expectation.violation
        @context.add_violation v.message, v.parameters
      end

      self
    end

    def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      self
    end

    def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      self
    end

    def violations : AVD::Violation::ConstraintViolationListInterface
      @context.violations
    end

    def expect_no_validate : Nil
      @expect_no_validate = true
    end

    def expect_validation(
      call : Int32,
      property_path : String?,
      value : _,
      group : Array(String) | String | AVD::Constraints::GroupSequence | Nil,
      violation : AVD::Violation::ConstraintViolationInterface? = nil,
      &block : Array(AVD::Constraint) | AVD::Constraint | Nil -> Nil
    )
      if property_path
        @expected_at_path.insert call, property_path
      end

      @expected_validate.insert call, Expectation.new value, group, block, violation
    end
  end

  @group : String
  @metadata : Nil = nil
  @object : Nil = nil
  @value : String | Array(String)
  @root : String
  @property_path : String
  @constraint : AVD::Constraint
  @context : AVD::ExecutionContext?
  @validator : AVD::ConstraintValidatorInterface?
  @expected_violations : Array(AVD::Violation::ConstraintViolationListInterface)
  @call : Int32

  protected def initialize
    @group = "my_group"
    @value = "invalid_value"
    @root = "root"
    @property_path = "property.path"

    @constraint = AVD::Constraints::NotBlank.new
    @expected_violations = Array(AVD::Violation::ConstraintViolationListInterface).new
    @call = 0

    ctx = self.create_context
    validator = self.create_validator
    validator.context = ctx

    @context = ctx
    @validator = validator
  end

  # Returns a new validator instance for the constraint being tested.
  abstract def create_validator : AVD::ConstraintValidatorInterface

  # Returns the class of the constraint being tested.
  abstract def constraint_class : AVD::Constraint.class

  # Returns a new constraint instance based on `#constraint_class` and the provided *args*.
  def new_constraint(**args) : AVD::Constraint
    self.constraint_class.new **args
  end

  # Asserts that no violations were added to the context.
  def assert_no_violation(*, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    unless (violation_count = self.context.violations.size).zero?
      fail "0 violations expected but got #{violation_count}.", file, line
    end
  end

  # Asserts a violation with the provided *message* was added to the context.
  def assert_violation(message : String) : Nil
    self.build_violation(message).assert_violation
  end

  # Asserts a violation with the provided provided *message*, and *code* was added to the context.
  def assert_violation(message : String, code : String) : Nil
    self.build_violation(message, code).assert_violation
  end

  # Asserts a violation with the provided *message*, *code*, and *value* parameter was added to the context.
  def assert_violation(message : String, code : String, value : _) : Nil
    self.build_violation(message, code, value).assert_violation
  end

  # Returns an `AVD::Spec::ConstraintValidatorTestCase::Assertion` with the provided *message* preset.
  def build_violation(message : String) : AVD::Spec::ConstraintValidatorTestCase::Assertion
    Assertion.new self.context, message, @constraint
  end

  # Returns an `AVD::Spec::ConstraintValidatorTestCase::Assertion` with the provided *message*, and *code* preset.
  def build_violation(message : String, code : String) : AVD::Spec::ConstraintValidatorTestCase::Assertion
    self.build_violation(message).code(code)
  end

  # Returns an `AVD::Spec::ConstraintValidatorTestCase::Assertion` with the provided *message*, *code*, and *value* parameter preset.
  def build_violation(message : String, code : String, value : _) : AVD::Spec::ConstraintValidatorTestCase::Assertion
    self.build_violation(message).code(code).add_parameter("{{ value }}", value)
  end

  # Asserts that a validation within a specific context occurs with the provided *property_path*, *value*, *constraints*, and optionally *groups*.
  #
  # See `CollectionValidatorTestCase` for an example.
  def expect_validate_value_at(
    idx : Int32,
    property_path : String,
    value : _,
    constraints : Array(AVD::Constraint) | AVD::Constraint,
    groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil,
  )
    raise "BUG: Null context" unless c = @context

    contextual_validator = c.validator.in_context(c).as AssertingContextualValidator
    contextual_validator.expect_validation idx, property_path, value, groups do |passed_constraints|
      constraints.should eq passed_constraints
    end
  end

  # Can be used to have a nested validator return the correct violations when used within another validator.
  #
  # Creates a separate validation context, validating the provided *value* against the provided *constraint*,
  # causing the resulting violations to be returned from the inner validator as they would be in a non-test context.
  #
  # See `AVD::Constraints::ISIN::Validator`, and its related specs, for an example.
  def expect_violation_at(idx : Int, value : _, constraint : AVD::Constraint) : AVD::Violation::ConstraintViolationListInterface
    ctx = self.create_context

    validator = constraint.validated_by.new
    validator.context = ctx
    validator.validate value, constraint

    @expected_violations << ctx.violations

    ctx.violations
  end

  # Overrides the value/node currently being validated.
  def value=(value) : Nil
    @value = value
    self.context.set_node(@value, @object, @metadata, @property_path)
  end

  # Returns a reference to the context used for the current test.
  def context : AVD::ExecutionContext
    @context.not_nil!
  end

  # Returns the validator instance returned via `#create_validator`.
  def validator : AVD::ConstraintValidatorInterface
    @validator.not_nil!
  end

  private def create_context : AVD::ExecutionContext
    validator = MockValidator.new do
      (@expected_violations[@call]? || AVD::Violation::ConstraintViolationList.new).tap { @call += 1 }
    end

    ctx = AVD::ExecutionContext.new validator, @root
    ctx.group = @group
    ctx.set_node @value, @object, @metadata, @property_path
    ctx.constraint = @constraint

    contextual_validator = AssertingContextualValidator.new ctx
    validator.contextual_validator = contextual_validator

    ctx
  end
end
