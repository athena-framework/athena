# Defines common logic for comparison based constraints, such as `AVD::Constraints::GreaterThan`, or `AVD::Constraints::EqualTo`.
module Athena::Validator::Constraints::AbstractComparison(ValueType)
  # Returns the expected value.
  getter value : ValueType

  # Returns the type of the expected value.
  getter value_type : ValueType.class = ValueType

  def initialize(
    @value : ValueType,
    message : String = default_error_message,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  # Returns the `AVD::Constraint#message` for this constraint.
  abstract def default_error_message : String
end
