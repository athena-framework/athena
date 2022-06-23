require "./constraint_validator_factory_interface"

# Basic implementation of `AVD::ConstraintValidatorFactoryInterface`.
struct Athena::Validator::ConstraintValidatorFactory
  include Athena::Validator::ConstraintValidatorFactoryInterface

  @validators : Hash(AVD::ConstraintValidator.class, AVD::ConstraintValidator) = Hash(AVD::ConstraintValidator.class, AVD::ConstraintValidator).new

  # :nodoc:
  #
  # Overload to support DI.
  def initialize(constraint_validators : Array(AVD::ServiceConstraintValidator) = [] of AVD::ServiceConstraintValidator)
    constraint_validators.each do |validator|
      @validators[validator.class] = validator
    end
  end

  # Returns an `AVD::ConstraintValidator` based on the provided *validator_class*.
  #
  # NOTE: This overloaded is intended to be used for service based validators that are already
  # instantiated and were provided via DI.
  def validator(for validator_class : AVD::ServiceConstraintValidator.class) : AVD::ConstraintValidator
    @validators[validator_class]
  end

  # Returns an `AVD::ConstraintValidator` based on the provided *validator_class*.
  def validator(for validator_class : AVD::ConstraintValidator.class) : AVD::ConstraintValidator
    if validator = @validators[validator_class]?
      return validator
    end

    @validators[validator_class] = validator_class.new
  end
end
