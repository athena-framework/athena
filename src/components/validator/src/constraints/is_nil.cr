# Validates that a value is `nil`.
#
# # Configuration
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This value should be null.`
#
# The message that will be shown if the value is not `nil`.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
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
class Athena::Validator::Constraints::IsNil < Athena::Validator::Constraint
  NOT_NIL_ERROR = "2c88e3c7-9275-4b9b-81b4-48c6c44b1804"

  @@error_names = {
    NOT_NIL_ERROR => "NOT_NIL_ERROR",
  }

  def initialize(
    message : String = "This value should be null.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::IsNil) : Nil
      return if value.nil?

      self.context.add_violation constraint.message, NOT_NIL_ERROR, value
    end
  end
end
