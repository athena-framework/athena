require "athena-spec"

require "./spec/abstract_validator_test_case"
require "./spec/constraint_validator_test_case"
require "./spec/validator_test_case"

# A set of testing utilities/types to aid in testing `Athena::Validator` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec" and "athena-spec".
# require "athena-validator/spec"
# ```
#
# Add `Athena::Spec` as a development dependency, then run a `shards install`.
# See the individual types for more information.
module Athena::Validator::Spec
  # Extension of `AVD::Spec::ConstraintValidatorTestCase` used for testing `AVD::Constraints::AbstractComparison` based constraints.
  #
  # ### Example
  #
  # Using the spec from `AVD::Constraints::EqualTo`:
  #
  # ```
  # # Makes for a bit less typing when needing to reference the constraint.
  # private alias CONSTRAINT = AVD::Constraints::EqualTo
  #
  # # Define our test case inheriting from the abstract `ComparisonConstraintValidatorTestCase`.
  # struct EqualToValidatorTest < AVD::Spec::ComparisonConstraintValidatorTestCase
  #   # Returns a Tuple of Tuples representing valid comparisons.
  #   # The first item  is the actual value and the second item is the expected value.
  #   def valid_comparisons : Tuple
  #     {
  #       {3, 3},
  #       {'a', 'a'},
  #       {"a", "a"},
  #       {Time.utc(2020, 4, 7), Time.utc(2020, 4, 7)},
  #       {nil, false},
  #     }
  #   end
  #
  #   # Returns a Tuple of Tuples representing invalid comparisons.
  #   # The first item  is the actual value and the second item is the expected value.
  #   def invalid_comparisons : Tuple
  #     {
  #       {1, 3},
  #       {'b', 'a'},
  #       {"b", "a"},
  #       {Time.utc(2020, 4, 8), Time.utc(2020, 4, 7)},
  #     }
  #   end
  #
  #   # The error code related to the current CONSTRAINT.
  #   def error_code : String
  #     CONSTRAINT::NOT_EQUAL_ERROR
  #   end
  #
  #   # Implement some abstract defs to return the validator and constraint class.
  #   def create_validator : AVD::ConstraintValidatorInterface
  #     CONSTRAINT::Validator.new
  #   end
  #
  #   def constraint_class : AVD::Constraint.class
  #     CONSTRAINT
  #   end
  # end
  # ```
  abstract struct ComparisonConstraintValidatorTestCase < ConstraintValidatorTestCase
    # A `Tuple` of tuples representing valid comparisons.
    abstract def valid_comparisons : Tuple

    # A `Tuple` of tuples representing invalid comparisons.
    abstract def invalid_comparisons : Tuple

    # The code for the current constraint.
    abstract def error_code : String

    @[DataProvider("valid_comparisons")]
    def test_valid_comparisons(actual, expected) : Nil
      self.validator.validate actual, self.new_constraint value: expected
      self.assert_no_violation
    end

    @[DataProvider("invalid_comparisons")]
    def test_invalid_comparisons(actual, expected : T) : Nil forall T
      self.validator.validate actual, self.new_constraint value: expected, message: "my_message"

      self
        .build_violation("my_message", self.error_code, actual)
        .add_parameter("{{ compared_value }}", expected)
        .add_parameter("{{ compared_value_type }}", T)
        .assert_violation
    end
  end

  # A spec implementation of `AVD::Validator::ContextualValidatorInterface`.
  #
  # Allows settings the violations that should be returned, defaulting to no violations.
  class MockContextualValidator
    include Athena::Validator::Validator::ContextualValidatorInterface

    setter violations : AVD::Violation::ConstraintViolationListInterface

    def initialize(@violations : AVD::Violation::ConstraintViolationListInterface = AVD::Violation::ConstraintViolationList.new); end

    # :inherit:
    def at_path(path : String) : AVD::Validator::ContextualValidatorInterface
      self
    end

    # :inherit:
    def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      self
    end

    # :inherit:
    def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      self
    end

    # :inherit:
    def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface
      self
    end

    # :inherit:
    def violations : AVD::Violation::ConstraintViolationListInterface
      @violations
    end
  end

  # A spec implementation of `AVD::Validator::ValidatorInterface`.
  #
  # Allows settings the violations that should be returned, defaulting to no violations.
  # Also allows providing a block that is called for each validated value.
  # E.g. to allow dynamically configuring the returned violations after it is instantiated.
  class MockValidator
    include Athena::Validator::Validator::ValidatorInterface

    setter violations_callback : Proc(AVD::Violation::ConstraintViolationListInterface)

    def self.new(violations : AVD::Violation::ConstraintViolationListInterface = AVD::Violation::ConstraintViolationList.new) : self
      new ->{ violations }
    end

    def initialize(&@violations_callback : -> AVD::Violation::ConstraintViolationListInterface); end

    # :inherit:
    def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
      @violations_callback.call
    end

    # :inherit:
    def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
      @violations_callback.call
    end

    # :inherit:
    def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
      @violations_callback.call
    end

    # :inherit:
    def start_context(root = nil) : AVD::Validator::ContextualValidatorInterface
      MockContextualValidator.new @violations_callback.call
    end

    # :inherit:
    def in_context(context : AVD::ExecutionContextInterface) : AVD::Validator::ContextualValidatorInterface
      MockContextualValidator.new @violations_callback.call
    end
  end

  # A spec implementation of `AVD::Metadata::MetadataFactoryInterface`, supporting a fixed number of additional metadatas
  struct MockMetadataFactory(T1, T2, T3, T4, T5)
    include AVD::Metadata::MetadataFactoryInterface

    @metadatas = Hash(AVD::Validatable::Class, AVD::Metadata::ClassMetadata(T1) |
                                               AVD::Metadata::ClassMetadata(T2) |
                                               AVD::Metadata::ClassMetadata(T3) |
                                               AVD::Metadata::ClassMetadata(T4) |
                                               AVD::Metadata::ClassMetadata(T5)).new

    def metadata(object : AVD::Validatable) : AVD::Metadata::ClassMetadata
      if metadata = @metadatas[object.class]?
        return metadata
      end

      object.class.validation_class_metadata
    end

    def add_metadata(klass : AVD::Validatable::Class, metadata : AVD::Metadata::ClassMetadata) : Nil
      @metadatas[klass] = metadata
    end
  end

  # A constraint that always adds a violation.
  class FailingConstraint < AVD::Constraint
    def initialize(
      message : String = "Failed",
      groups : Array(String) | String | Nil = nil,
      payload : Hash(String, String)? = nil
    )
      super message, groups, payload
    end

    struct Validator < AVD::ConstraintValidator
      def validate(value : _, constraint : FailingConstraint) : Nil
        self.context.add_violation constraint.message
      end
    end
  end

  # An `AVD::Validatable` entity using an `Array` based group sequence.
  record EntitySequenceProvider, sequence : Array(String | Array(String)) do
    include AVD::Validatable
    include AVD::Constraints::GroupSequence::Provider

    def group_sequence : Array(String | Array(String)) | AVD::Constraints::GroupSequence
      @sequence || AVD::Constraints::GroupSequence.new [] of String
    end
  end

  # An `AVD::Validatable` entity using an `AVD::Constraints::GroupSequence` based group sequence.
  record EntityGroupSequenceProvider, sequence : AVD::Constraints::GroupSequence do
    include AVD::Validatable
    include AVD::Constraints::GroupSequence::Provider

    def group_sequence : Array(String | Array(String)) | AVD::Constraints::GroupSequence
      @sequence || Array(String | Array(String)).new
    end
  end
end
