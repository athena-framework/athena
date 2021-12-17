require "./validator_error"

# Raised when an `AVD::ConstraintValidatorInterface` is unable to validate a value of an unsupported type.
#
# See `AVD::ConstraintValidator#raise_invalid_type`.
class Athena::Validator::Exceptions::UnexpectedValueError < Athena::Validator::Exceptions::ValidatorError
  # A string representing a union of the supported_type(s).
  getter supported_types : String

  def initialize(value : _, @supported_types : String)
    super "Expected argument of type '#{supported_types}', '#{typeof(value)}' given."
  end
end
