require "./composite"

# Validates each element of an `Iterable` is valid based on a collection of constraints.
#
# ## Configuration
#
# ### Required Arguments
#
# #### constraints
#
# **Type:** `Array(AVD::Constraint) | AVD::Constraint`
#
# The `AVD::Constraint`(s) that you want to apply to each element of the underlying iterable.
#
# ### Optional Arguments
#
# NOTE: This constraint does not support a `message` argument.
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
#
# ## Usage
#
# ```
# class Example
#   include AVD::Validatable
#
#   def initialize(@strings : Array(String)); end
#
#   # Assert each string is not blank and is at least 5 characters long.
#   @[Assert::All([
#     @[Assert::NotBlank],
#     @[Assert::Size(5..)],
#   ])]
#   getter strings : Array(String)
# end
# ```
#
# NOTE: The annotation approach only supports two levels of nested annotations.
# Manually wire up the constraint via code if you require more than that.
class Athena::Validator::Constraints::All < Athena::Validator::Constraints::Composite
  def initialize(
    constraints : Array(AVD::Constraint) | AVD::Constraint,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super constraints, "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : Hash?, constraint : AVD::Constraints::All) : Nil
      return if value.nil?

      self.with_validator do |validator|
        value.each do |k, v|
          validator.at_path("[#{k}]").validate(v, constraint.constraints)
        end
      end
    end

    # :inherit:
    def validate(value : Indexable?, constraint : AVD::Constraints::All) : Nil
      return if value.nil?

      self.with_validator do |validator|
        value.each_with_index do |item, idx|
          validator.at_path("[#{idx}]").validate(item, constraint.constraints)
        end
      end
    end

    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::All) : NoReturn
      self.raise_invalid_type value, "Hash | Indexable"
    end

    private def with_validator(& : AVD::Validator::ContextualValidatorInterface ->) : Nil
      yield self.context.validator.in_context self.context
    end
  end
end
