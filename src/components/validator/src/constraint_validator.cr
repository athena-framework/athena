require "./constraint_validator_interface"

# Basic implementation of `AVD::ConstraintValidatorInterface`.
abstract struct Athena::Validator::ConstraintValidator
  include Athena::Validator::ConstraintValidatorInterface

  # :inherit:
  def context : AVD::ExecutionContextInterface
    @context.not_nil!
  end

  # :nodoc:
  def context=(@context : AVD::ExecutionContextInterface); end

  # :inherit:
  def validate(value : _, constraint : AVD::Constraint) : Nil
    # Noop if a given validator doesn't support a given type of value
  end

  # Can be used to raise an `AVD::Exceptions::UnexpectedValueError`
  # in case `self` is only able to validate values of the *supported_types*.
  #
  # ```
  # # Define a validate method to catch values of other types.
  # # Overloads above would handle the valid types.
  # def validate(value : _, constraint : AVD::Constraints::MyConstraint) : Nil
  #   self.raise_invalid_type value, "Int | Float"
  # end
  # ```
  #
  # This would result in a violation with the message `This value should be a valid: Int | Float`
  # being added to the current `#context`.
  def raise_invalid_type(value : _, supported_types : String) : NoReturn
    raise AVD::Exceptions::UnexpectedValueError.new value, supported_types
  end
end

# Extension of `AVD::ConstraintValidator` used to denote a service validator
# that can be used with [Athena Dependency Injection](https://github.com/athena-framework/dependency-injection).
abstract struct Athena::Validator::ServiceConstraintValidator < Athena::Validator::ConstraintValidator
  macro inherited
    def self.new : NoReturn
      # Validators of this type will be injected via DI and not directly instantiated within the factory.
      raise ""
    end
  end
end

# Compiler doesn't like there not being any instances of this
private struct FakeConstraintValidator < Athena::Validator::ServiceConstraintValidator; end
