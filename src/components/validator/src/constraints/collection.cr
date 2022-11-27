class Athena::Validator::Constraints::Collection < Athena::Validator::Constraints::Composite
  MISSING_FIELD_ERROR = "af103ee5-3bcb-448e-98ad-b4ef76c05060"
  NO_SUCH_FIELD_ERROR = "70e60467-4078-4f92-acf9-d1e6683d0922"

  @@error_names = {
    MISSING_FIELD_ERROR => "MISSING_FIELD_ERROR",
    NO_SUCH_FIELD_ERROR => "NO_SUCH_FIELD_ERROR",
  }

  getter? allow_extra_fields : Bool
  getter? allow_missing_fields : Bool

  getter extra_fields_message : String
  getter missing_fields_message : String

  def initialize(
    fields : Hash(String, AVD::Constraint | Array(AVD::Constraint)),
    @allow_extra_fields : Bool = false,
    @allow_missing_fields : Bool = false,
    @extra_fields_message : String = "This field was not expected",
    @missing_fields_message : String = "This field is missing",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    constraints = Hash(String, AVD::Constraint).new

    fields.each do |key, value|
      constraints[key] = !value.is_a?(AVD::Constraints::Optional) && !value.is_a?(AVD::Constraints::Required) ? AVD::Constraints::Required.new(value) : value
    end

    super constraints, "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : Enumerable({K, V}), constraint : AVD::Constraints::Collection) : Nil forall K, V
      context = self.context

      constraint.constraints.each do |field, field_constraint|
        field_constraint = field_constraint.as AVD::Constraints::Existence

        if value.has_key? field
          context
            .validator
            .in_context(context)
            .at_path("[#{field}]")
            .validate(value[field], field_constraint.constraints.values)
        elsif !field_constraint.is_a?(AVD::Constraints::Optional) && !constraint.allow_missing_fields?
          context
            .build_violation(constraint.missing_fields_message)
            .code(MISSING_FIELD_ERROR)
            .add_parameter("{{ field }}", field)
            .at_path("[#{field}]")
            .add
        end
      end

      unless constraint.allow_extra_fields?
        value.each do |field, field_value|
          unless constraint.constraints.has_key? field
            context
              .build_violation(constraint.extra_fields_message)
              .code(NO_SUCH_FIELD_ERROR)
              .add_parameter("{{ field }}", field)
              .at_path("[#{field}]")
              .add
          end
        end
      end
    end
  end
end
