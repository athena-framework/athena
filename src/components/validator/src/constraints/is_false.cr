# Validates that a value is `false`.
#
# ## Configuration
#
# ### Optional Arguments
#
# #### message
#
# **Type:** `String` **Default:** `This value should be false.`
#
# The message that will be shown if the value is not `false`.
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
class Athena::Validator::Constraints::IsFalse < Athena::Validator::Constraint
  NOT_FALSE_ERROR = "55c076a0-dbaf-453c-90cf-b94664276dbc"

  @@error_names = {
    NOT_FALSE_ERROR => "NOT_FALSE_ERROR",
  }

  def initialize(
    message : String = "This value should be false.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::IsFalse) : Nil
      return if value.nil? || value == false

      self.context.add_violation constraint.message, NOT_FALSE_ERROR, value
    end
  end
end
