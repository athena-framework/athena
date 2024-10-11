# Allows creating a custom set of reusable constraints, representing rules to use consistently across your application.
#
# NOTE: See the [custom constraint][Athena::Validator::Constraint--custom-constraints] documentation for information on defining custom constraints.
#
# # Configuration
#
# ## Optional Arguments
#
# NOTE: This constraint does not support a `message` argument.
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
#
# # Usage
#
# This constraint is not used directly on its own;
# instead it's used to create another constraint.
#
# ```
# # Define a compound constraint to centralize the logic to validate a password.
# #
# # NOTE: The constraint _MUST_ be defined within the `AVD::Constraints` namespace for implementation reasons.  This may change in the future.
# class AVD::Constraints::ValidPassword < AVD::Constraints::Compound
#   # Define a method that returns an array of the constraints we want to be a part of `self`.
#   def constraints : Type
#     [
#       AVD::Constraints::NotBlank.new,       # Not empty/null
#       AVD::Constraints::Size.new(12..),     # At least 12 characters longs
#       AVD::Constraints::Regex.new(/^\d.*/), # Must start with a number
#     ]
#   end
# end
# ```
#
# We can then use this constraint as we would any other.
#
# Either as an annotation
#
# ```
# @[Assert::ValidPassword]
# getter password : String
# ```
# or directly.
#
# ```
# constraint = AVD::Constraints::ValidPassword.new
# ```
abstract class Athena::Validator::Constraints::Compound < Athena::Validator::Constraints::Composite
  def initialize(
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super self.constraints, "", groups, payload
  end

  def validated_by : AVD::ConstraintValidator.class
    AVD::Constraints::Compound::Validator
  end

  abstract def constraints : AVD::Constraints::Composite::Type

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Compound) : Nil
      context = self.context

      validator = context.validator.in_context context

      validator.validate value, constraint.@constraints.values
    end
  end
end
