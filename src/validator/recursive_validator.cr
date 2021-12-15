require "../constraint_validator_factory_interface"

# A recursive implementation of `AVD::Validator::ValidatorInterface`.
#
# See `Athena::Validator.validator`.
class Athena::Validator::Validator::RecursiveValidator
  include Athena::Validator::Validator::ValidatorInterface

  @validator_factory : AVD::ConstraintValidatorFactoryInterface
  @metadata_factory : AVD::Metadata::MetadataFactoryInterface

  def initialize(validator_factory : AVD::ConstraintValidatorFactoryInterface? = nil, metadata_factory : AVD::Metadata::MetadataFactoryInterface? = nil)
    @validator_factory = validator_factory || AVD::ConstraintValidatorFactory.new
    @metadata_factory = metadata_factory || AVD::Metadata::MetadataFactory.new
  end

  # :inherit:
  def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
    start_context(value).validate(value, constraints, groups).violations
  end

  # :inherit:
  def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
    start_context(object).validate_property(object, property_name, groups).violations
  end

  # :inherit:
  def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Violation::ConstraintViolationListInterface
    start_context(object).validate_property_value(object, property_name, value, groups).violations
  end

  # :inherit:
  def start_context(root = nil) : AVD::Validator::ContextualValidatorInterface
    AVD::Validator::RecursiveContextualValidator.new create_context(root), @validator_factory, @metadata_factory
  end

  # :inherit:
  def in_context(context : AVD::ExecutionContextInterface) : AVD::Validator::ContextualValidatorInterface
    AVD::Validator::RecursiveContextualValidator.new context, @validator_factory, @metadata_factory
  end

  private def create_context(root = nil) : AVD::ExecutionContextInterface
    AVD::ExecutionContext.new self, root
  end
end
