# Tells the validator that it should also validate objects embedded as properties on an object being validated.
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
# Without this constraint, objects embedded in another object are not valided.
#
# ```
# class SubObjectOne
#   include AVD::Validatable
#
#   @[Assert::NotBlank]
#   getter string : String = ""
# end
#
# class SubObjectTwo
#   include AVD::Validatable
#
#   @[Assert::NotBlank]
#   getter string : String = ""
# end
#
# class MyObject
#   include AVD::Validatable
#
#   # This object is not validated when validating `MyObject`.
#   getter sub_object_one : SubObjectOne = SubObjectOne.new
#
#   # Have the validator also validate `SubObjectTwo` when validating `MyObject`.
#   @[Assert::Valid]
#   getter sub_object_two : SubObjectTwo = SubObjectTwo.new
# end
# ```
class Athena::Validator::Constraints::Valid < Athena::Validator::Constraint
  getter? traverse : Bool

  def initialize(
    @traverse : Bool = true,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Valid) : Nil
      return if value.nil?

      self
        .context
        .validator
        .in_context(self.context)
        .validate value, groups: self.context.group
    end
  end
end
