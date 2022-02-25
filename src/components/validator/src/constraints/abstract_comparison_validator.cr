# Defines common logic for comparison based constraint validators.
abstract class Athena::Validator::Constraints::ComparisonValidator < Athena::Validator::ConstraintValidator
  # Returns `true` if the provided *actual* and *expected* values are compatible, otherwise `false`.
  abstract def compare_values(actual : _, expected : _) : Bool

  # Returns the expected error code for `self`.
  abstract def error_code : String

  # :inherit:
  def validate(value : _, constraint : AVD::Constraints::AbstractComparison) : Nil
    return if value.nil?

    compared_value = constraint.value

    return if self.compare_values value, compared_value

    self
      .context
      .build_violation(constraint.message, self.error_code, value)
      .add_parameter("{{ compared_value }}", compared_value)
      .add_parameter("{{ compared_value_type }}", constraint.value_type)
      .add
  end
end
