require "athena-validator"

require "./validator/validation_failed_exception"

@[ADI::Register]
class Athena::Validator::Validator::RecursiveValidator; end

@[ADI::Autoconfigure(tags: ["athena.validator.constraint_validator"])]
abstract class AVD::ServiceConstraintValidator; end

@[ADI::Register]
struct Athena::Validator::ConstraintValidatorFactory; end

ADI.bind constraint_validators : Array(AVD::ServiceConstraintValidator), "!athena.validator.constraint_validator"
