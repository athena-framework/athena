# A validator that validates in a specific `AVD::ExecutionContextInterface` instance.
module Athena::Validator::Validator::ContextualValidatorInterface
  # Appends the provided *path* to the current `AVD::ExecutionContextInterface#property_path`.
  abstract def at_path(path : String) : AVD::Validator::ContextualValidatorInterface

  # Validates the provided *value*, optionally against the provided *constraints*, optionally using the provided *groups*.
  # `AVD::Constraint::DEFAULT_GROUP` is assumed if no *groups* are provided.
  abstract def validate(value : _, constraints : Array(AVD::Constraint) | AVD::Constraint | Nil = nil, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface

  # Validates a property of the provided *object* against the constraints defined for that property, optionally using the provided *groups*.
  # `AVD::Constraint::DEFAULT_GROUP` is assumed if no *groups* are provided.
  abstract def validate_property(object : AVD::Validatable, property_name : String, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface

  # Validates a value against the constraints defined on the property of the provided *object*.
  # `AVD::Constraint::DEFAULT_GROUP` is assumed if no *groups* are provided.
  abstract def validate_property_value(object : AVD::Validatable, property_name : String, value : _, groups : Array(String) | String | AVD::Constraints::GroupSequence | Nil = nil) : AVD::Validator::ContextualValidatorInterface

  # Returns any violations that have been generated so far in the context of `self`.
  abstract def violations : AVD::Violation::ConstraintViolationListInterface
end
