# Validates a value against a collection of constraints, stopping once the first violation is raised.
#
# ## Configuration
#
# ### Required Arguments
#
# #### constraints
#
# **Type:** `Array(AVD::Constraint) | AVD::Constraint`
#
# The `AVD::Constraint`(s) that are to be applied sequentially.
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
# Suppose you have an object with a `address` property which should meet the following criteria:
#
# * Is not a blank string
# * Is at least 10 characters long
# * Is in a specific format
# * Is geolocalizable using an external API
#
# If you were to apply all of these constraints to the `address` property, you may run into some problems.
# For example, multiple violations may be added for the same property, or you may perform a useless and heavy
# external call to geolocalize the address when it is not in a proper format.
#
# To solve this we can validate these constraints sequentially.
#
# ```
# class Location
#   include AVD::Validatable
#
#   PATTERN = /some_pattern/
#
#   def initialize(@address : String); end
#
#   @[Assert::Sequentially([
#     @[Assert::NotBlank],
#     @[Assert::Size(10..)],
#     @[Assert::Regex(Location::PATTERN)],
#     @[Assert::CustomGeolocalizationConstraint],
#   ])]
#   getter address : String
# end
# ```
#
# NOTE: The annotation approach only supports two levels of nested annotations.
# Manually wire up the constraint via code if you require more than that.
class Athena::Validator::Constraints::Sequentially < Athena::Validator::Constraints::Composite
  def initialize(
    constraints : Array(AVD::Constraint) | AVD::Constraint,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super constraints, "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Sequentially) : Nil
      validator = self.context.validator.in_context self.context

      origional_count = validator.violations.size

      constraint.constraints.each do |c|
        break if origional_count != validator.validate(value, c).violations.size
      end
    end
  end
end
