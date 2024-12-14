# Validates that a value is `true`.
#
# ```
# class Post
#   include AVD::Validatable
#
#   def initialize(@is_published : Bool); end
#
#   @[Assert::IsTrue]
#   property is_published : Bool
# end
# ```
#
# # Configuration
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This value should be true.`
#
# The message that will be shown if the value is not `true`.
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
class Athena::Validator::Constraints::IsTrue < Athena::Validator::Constraint
  NOT_TRUE_ERROR = "beabd93e-3673-4dfc-8796-01bd1504dd19"

  @@error_names = {
    NOT_TRUE_ERROR => "NOT_TRUE_ERROR",
  }

  def initialize(
    message : String = "This value should be true.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::IsTrue) : Nil
      return if value.nil? || value == true

      self.context.add_violation constraint.message, NOT_TRUE_ERROR, value
    end
  end
end
