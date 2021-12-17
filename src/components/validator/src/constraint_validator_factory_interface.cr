# Provides validator instances based on a validator class, caching the instance.
#
# `AVD::ServiceConstraintValidator`s are instantiated externally and injected into the factory.
module Athena::Validator::ConstraintValidatorFactoryInterface
  # Returns an `AVD::ConstraintValidatorInterface` instance based on the provided *validator_class*.
  abstract def validator(validator : AVD::ConstraintValidator.class) : AVD::ConstraintValidatorInterface
end
