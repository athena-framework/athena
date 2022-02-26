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
#     # Asssert a violation with the expected message, code, and value parameter is added to the context.
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
# This approach also allows using `ASPEC::TestCase::DataProvider`s for reducing duplication withing your test.
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

  @group : String
  @metadata : Nil = nil
  @object : Nil = nil
  @value : String | Array(String)
  @root : String
  @property_path : String
  @constraint : AVD::Constraint
  @context : AVD::ExecutionContext?
  @validator : AVD::ConstraintValidatorInterface?

  protected def initialize
    @group = "my_group"
    @value = "invalid_value"
    @root = "root"
    @property_path = "property.path"

    @constraint = AVD::Constraints::NotBlank.new

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
    validator = MockValidator.new

    ctx = AVD::ExecutionContext.new validator, @root
    ctx.group = @group
    ctx.set_node @value, @object, @metadata, @property_path
    ctx.constraint = @constraint

    ctx
  end
end
