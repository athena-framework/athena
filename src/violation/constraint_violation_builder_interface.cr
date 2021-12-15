# A [Builder Pattern](https://en.wikipedia.org/wiki/Builder_pattern) type for building `AVD::Violation::ConstraintViolationInterface`s.
#
# Allows using the methods defined on `self` to construct the desired violation before adding it to the context.
module Athena::Validator::Violation::ConstraintViolationBuilderInterface
  # Adds the violation to the current `AVD::ExecutionContextInterface`.
  abstract def add : Nil

  # Adds a parameter with the provided *key* and *value* to the violations' `AVD::Violation::ConstraintViolationInterface#parameters`.
  # The provided *value* is stringified via `#to_s` before being added to the parameters.
  #
  # Returns `self` for chaining.
  abstract def add_parameter(key : String, value : _) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets the `AVD::Violation::ConstraintViolationInterface#property_path`.
  #
  # Returns `self` for chaining.
  abstract def at_path(path : String) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets the `AVD::Violation::ConstraintViolationInterface#cause`
  #
  # Returns `self` for chaining.
  abstract def cause(cause : String?) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets the `AVD::Violation::ConstraintViolationInterface#code`
  #
  # Returns `self` for chaining.
  abstract def code(code : String?) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets the `AVD::Violation::ConstraintViolationInterface#constraint`
  #
  # Returns `self` for chaining.
  abstract def constraint(constraint : AVD::Constraint?) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets the `AVD::Violation::ConstraintViolationInterface#invalid_value`
  #
  # Returns `self` for chaining.
  abstract def invalid_value(value : _) : AVD::Violation::ConstraintViolationBuilderInterface

  # Sets `AVD::Violation::ConstraintViolationInterface#plural`
  #
  # Returns `self` for chaining.
  abstract def plural(number : Int32) : AVD::Violation::ConstraintViolationBuilderInterface

  # Overrides the entire `AVD::Violation::ConstraintViolationInterface#parameters` hash with the provided *parameters*.
  #
  # Returns `self` for chaining.
  abstract def set_parameters(parameters : Hash(String, String)) : AVD::Violation::ConstraintViolationBuilderInterface
end
