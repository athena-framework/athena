# Validates that a value is blank; meaning equal to an empty string or `nil`.
#
# ```
# class Profile
#   include AVD::Validatable
#
#   def initialize(@username : String); end
#
#   @[Assert::Blank]
#   property username : String
# end
# ```
#
# # Configuration
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This value should be blank.`
#
# The message that will be shown if the value is not blank.
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
class Athena::Validator::Constraints::Blank < Athena::Validator::Constraint
  NOT_BLANK_ERROR = "c815f901-c581-4fb7-a85d-b8c5bc757959"

  @@error_names = {
    NOT_BLANK_ERROR => "NOT_BLANK_ERROR",
  }

  def initialize(
    message : String = "This value should be blank.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Blank) : Nil
      return if value.nil?
      return if value.responds_to?(:blank?) && value.blank?

      self.context.add_violation constraint.message, NOT_BLANK_ERROR, value
    end
  end
end
