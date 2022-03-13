# Validates that all elements of an `Indexable` are unique.
#
# # Configuration
#
# ## Optional Arguments
#
# ### message
#
# **Type:** `String` **Default:** `This collection should contain only unique elements.`
#
# The message that will be shown if at least one element is repeated in the collection.
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
class Athena::Validator::Constraints::Unique < Athena::Validator::Constraint
  IS_NOT_UNIQUE_ERROR = "fd1f83d6-94b5-44bc-b39d-b1ff367ebfb8"

  @@error_names = {
    IS_NOT_UNIQUE_ERROR => "IS_NOT_UNIQUE_ERROR",
  }

  def initialize(
    message : String = "This collection should contain only unique elements.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : Indexable?, constraint : AVD::Constraints::Unique) : Nil
      return if value.nil?

      set = Set(typeof(value[0])).new value.size

      unless value.all? { |x| set.add?(x) }
        self.context.add_violation constraint.message, IS_NOT_UNIQUE_ERROR, value
      end
    end

    # :inherit:
    def compare_values(actual : _, expected : _) : NoReturn
      # TODO: Support checking if arbitrarily typed values are actually comparable once `#responds_to?` supports it.
      self.raise_invalid_type actual, "Indexable"
    end
  end
end
