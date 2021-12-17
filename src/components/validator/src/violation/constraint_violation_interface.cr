# Represents a violation of a constraint during validation.
#
# Each failed constraint that fails during validation; one or more violations are created.
# The violations store the violation message, the path to the failing element,
# and the root element originally passed to the validator.
module Athena::Validator::Violation::ConstraintViolationInterface
  # Returns the cause of the violation.
  abstract def cause : String?

  # Returns a unique machine readable error code representing `self.`
  # All constraints of a specific "type" should have the same code.
  abstract def code : String?

  # Returns the `AVD::Constraint` whose validation caused the violation, if any.
  abstract def constraint : AVD::Constraint?

  # Returns the value that caused the violation.
  abstract def invalid_value

  # Returns the violation message.
  abstract def message : String

  # Returns the raw violation message.
  #
  # The message template contains placeholders for the parameters returned via `#parameters`.
  abstract def message_template : String?

  # Returns the parameters used to render the `#message_template`.
  abstract def parameters : Hash(String, String)

  # Returns a number used to pluralize the violation message.
  #
  # The returned value is used to determine the right plurlaization form.
  abstract def plural : Int32?

  # Returns the path from the root element to the violation.
  abstract def property_path : String

  # Returns the element originally passed to the validator.
  abstract def root

  # Returns a `JSON` representation of `self`.
  abstract def to_json(builder : JSON::Builder) : Nil

  # Returns a string representation of `self`.
  abstract def to_s(io : IO) : Nil
end
