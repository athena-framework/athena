# Validates that a value is not `nil`.
#
# NOTE: Due to Crystal's static typing, when validating objects the property's type must be nilable,
# otherwise `nil` is inherently not allowed due to the compiler's type checking.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value should not be null.`
#
# The message that will be shown if the value is `nil`.
#
# ##### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
#
# #### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# #### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
class Athena::Validator::Constraints::NotNil < Athena::Validator::Constraint
  IS_NIL_ERROR = "c7e77b14-744e-44c0-aa7e-391c69cc335c"

  @@error_names = {
    IS_NIL_ERROR => "IS_NIL_ERROR",
  }

  def initialize(
    message : String = "This value should not be null.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::NotNil) : Nil
      return unless value.nil?

      self.context.add_violation constraint.message, IS_NIL_ERROR, value
    end
  end
end
