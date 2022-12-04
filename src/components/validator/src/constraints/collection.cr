# Can be used with any `Enumerable({K, V})` to validate each key in a different way.
# For example validating the `email` key via `AVD::Constraints::Email`, and the `inventory` key with the `AVD::Constraints::Range` constraint.
# The collection constraint can also ensure that certain collection keys are present and that extra keys are not present.
#
# TODO: Update it to be `Mappable` when/if https://github.com/crystal-lang/crystal/issues/10886 is implemented.
#
# # Usage
#
# ```
# data = {
#   "email"           => "...",
#   "email_signature" => "...",
# }
# ```
#
# For example, say you want to ensure the *email* field is a valid email,
# and that their *email_signature* is not blank nor over 100 characters long;
# without creating a dedicated class to represent the hash.
#
# ```
# constraint = AVD::Constraints::Collection.new({
#   "email"           => AVD::Constraints::Email.new,
#   "email_signature" => [
#     AVD::Constraints::NotBlank.new,
#     AVD::Constraints::Size.new(..100, max_message: "Your signature is too long"),
#   ],
# })
#
# validator.validate data, constraint
# ```
#
# The collection constraint expects a hash representing the keys in the collection, with the value being which constraint(s) should be executed against its value.
# From there we can go ahead and validate our data hash against the constraint.
#
# ## Presence and Absence of Fields
#
# This constraint also will return validation errors if any keys of a collection are missing, or if there are any unrecognized keys in the collection.
# This can be customized via the [allow_extra_fields](#allow_extra_fields) and [allow_missing_fields](#allow_missing_fields) configuration options respectively.
#
# If the latter was set to `true`, then either *email* or *email_signature* could be missing from the data hash, and no validation errors would occur.
#
# ## Required and Optional Constraints
#
# Each field in the collection is assumed to be required by default.
# While you could make everything optional via the setting [allow_missing_fields](#allow_missing_fields) to `true`,
# this is less than ideal in some cases when you only want to affect a single key, or a subset of keys.
#
# In this case, a single constraint, or array of constraints, can be wrapped via the `AVD::Constraints::Optional` or `AVD::Constraints::Required` constraints.
# For example, if you wanted to require that the *personal_email* field is not blank and is a valid email,
# but also have an optional *alternate_email* field that must be a valid email if supplied, you could set things up like:
#
# ```
# constraint = AVD::Constraints::Collection.new({
#   "personal_email" => AVD::Constraints::Required.new([
#     AVD::Constraints::NotBlank.new,
#     AVD::Constraints::Email.new,
#   ]),
#   "alternate_email" => AVD::Constraints::Optional.new([
#     AVD::Constraints::Email.new,
#   ] of AVD::Constraint),
# })
# ```
#
# In this way, even if [allow_missing_fields](#allow_missing_fields) is `true`, you would be able to omit *alternate_email* since it is optional.
# However, since *personal_email* is required, the not blank assertion will still be applied and a violation will occur if it is missing.
#
# ## Groups
#
# Any groups defined in nested constraints are automatically added to the collection constraint itself such that it can be traversed for all nested groups.
#
# ```
# constraint = AVD::Constraints::Collection.new({
#   "name"  => AVD::Constraints::NotBlank.new(groups: "basic"),
#   "email" => AVD::Constraints::NotBlank.new(groups: "contact"),
# })
#
# constraint.groups # => ["basic", "contact"]
# ```
#
# TIP: The collection constraint can be used to validate form data via a [URI::Param](https://crystal-lang.org/api/URI/Params.html) instance.
#
# # Configuration
#
# ## Required Arguments
#
# ### fields
#
# **Type:** `Hash(String, AVD::Constraint | Array(AVD::Constraint))`
#
# A hash defining the keys in the collection, and for which constraint(s) should be executed against them.
#
# ## Optional Arguments
#
# ### allow_extra_fields
#
# **Type:** `Bool` **Default:** `false`
#
# If extra fields in the collection other than those defined within [fields](#fields) are allowed. By default extra fields will result in a validation error.
#
# ### allow_missing_fields
#
# **Type:** `Bool` **Default:** `false`
#
# If the fields defined within [fields](#fields) are allowed to be missing. By default a validation error will be returned if one or more field is missing.
#
# ### extra_fields_message
#
# **Type:** `String` **Default:** `This field was not expected.`
#
# The message that will be shown if [allow_extra_fields](#allow_extra_fields) is `false` and a field in the collection was not defined within `#fields`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ field }}` - The name of the extra field.
#
# ### missing_fields_message
#
# **Type:** `String` **Default:** `This field is missing.`
#
# The message that will be shown if [allow_missing_fields](#allow_missing_fields) is `false` and a field defined within `#fields` is missing from the collection.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ field }}` - The name of the missing field.
#
# ### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# ### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
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
    @extra_fields_message : String = "This field was not expected.",
    @missing_fields_message : String = "This field is missing.",
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
