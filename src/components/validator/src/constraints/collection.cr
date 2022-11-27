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
    #
    # TODO: Support https://github.com/crystal-lang/crystal/issues/10886 when/if implemented.
    def validate(value : Enumerable({K, V})?, constraint : AVD::Constraints::Collection) : Nil forall K, V
      return if value.nil?

      context = self.context

      constraint.constraints.each do |field, field_constraint|
        field_constraint = field_constraint.as AVD::Constraints::Existence

        if value.has_key? field
          if field_constraint.constraints.size > 0
            context
              .validator
              .in_context(context)
              .at_path("[#{field}]")
              .validate(value[field], field_constraint.constraints.values)
          end
        elsif !field_constraint.is_a?(AVD::Constraints::Optional) && !constraint.allow_missing_fields?
          context
            .build_violation(constraint.missing_fields_message, MISSING_FIELD_ERROR)
            .at_path("[#{field}]")
            .add_parameter("{{ field }}", field)
            .invalid_value(nil)
            .add
        end
      end

      unless constraint.allow_extra_fields?
        value.each do |field, field_value|
          unless constraint.constraints.has_key? field
            context
              .build_violation(constraint.extra_fields_message, NO_SUCH_FIELD_ERROR)
              .at_path("[#{field}]")
              .add_parameter("{{ field }}", field)
              .invalid_value(field_value)
              .add
          end
        end
      end
    end

    # :inherit:
    def validate(actual : _, expected : _) : NoReturn
      self.raise_invalid_type actual, "Enumerable({K, V})"
    end
  end
end
