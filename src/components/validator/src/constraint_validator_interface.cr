# A constraint validator is responsible for implementing the actual validation logic for a given `AVD::Constraint`.
#
# Constraint validators should inherit from this type and implement a `#validate` method.
# Most commonly the validator type will be defined within the namespace of the related `AVD::Constraint` itself.
#
# The `#validate` method itself does not return anything.
# Violations are added to the current `#context`, either as a single error message, or augmented with additional metadata about the failure.
# See `AVD::ExecutionContextInterface` for more information on how violations can be added.
#
# ### Example
#
# ```
# class AVD::Constraints::MyConstraint < AVD::Constraint
#   # Initializer/etc for the constraint
#
#   class Validator < AVD::ConstraintValidator
#     # Define a validate method that handles values of any type, and our `MyConstraint` constraint.
#     def validate(value : _, constraint : AVD::Constraints::MyConstraint) : Nil
#       # Implement logic to determine if the value is valid.
#       # Violations should be added to the current `#context`,
#       # See `AVD::ExecutionContextInterface` for more information.
#     end
#   end
# end
# ```
#
# Overloads of the `#validate` method can also be used to handle validating values of different types independently.
# If the value cannot be handled by any of `self`'s validators, it is handled via `AVD::ConstraintValidator#validate`
# and is essentially a noop.
#
# If a `AVD::Constraint` can only support values of certain types, `AVD::ConstraintValidator#raise_invalid_type`
# in a catchall overload can be used to add an invalid type `AVD::Violation::ConstraintViolationInterface`.
#
# ```
# class Validator < AVD::ConstraintValidator
#   def validate(value : Number, constraint : AVD::Constraints::MyConstraint) : Nil
#     # Handle validating `Number` values
#   end
#
#   def validate(value : Time, constraint : AVD::Constraints::MyConstraint) : Nil
#     # Handle validating `Time` values
#   end
#
#   def validate(value : _, constraint : AVD::Constraints::MyConstraint) : Nil
#     # Add an invalid type violation for values of all other types.
#     self.raise_invalid_type value, "Number | Time"
#   end
# end
# ```
#
# NOTE:  Normally custom validators should not handle `nil` or `blank` values as they are handled via other constraints.
#
# ### Service Based Validators
#
# If you're using `Athena::Validator` within the Athena ecosystem,
# constraint validators can also be defined as services if they require external dependencies.
# See `AVD::ServiceConstraintValidator` and the [validator](/architecture/validator) component documentation in the external documentation for more information.
module Athena::Validator::ConstraintValidatorInterface
  # Validate the provided *value* against the provided *constraint*.
  #
  # Violations should be added to the current `#context`.
  abstract def validate(value : _, constraint : AVD::Constraint) : Nil

  # Returns the a reference to the `AVD::ExecutionContextInterface`
  # to which violations within `self` should be added.
  #
  # See the type for more information.
  abstract def context : AVD::ExecutionContextInterface

  # Internal

  # :nodoc:
  abstract def context=(context : AVD::ExecutionContextInterface)
end
