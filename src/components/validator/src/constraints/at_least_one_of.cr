require "./composite"

# Validates that a value satisfies at least one of the provided constraints.
# Validation stops as soon as one constraint is satisfied.
#
# # Configuration
#
# ## Required Arguments
#
# ### constraints
#
# **Type:** `Array(AVD::Constraint) | AVD::Constraint`
#
# The `AVD::Constraint`(s) from which at least one of has to be satisfied in order for the validation to succeed.
#
# ## Optional Arguments
#
# ### include_internal_messages
#
# **Type:** `Bool` **Default:** `true`
#
# If the validation failed message should include the list of messages for the internal constraints.
# See the [message](#message) argument for an example.
#
# ### message_collection
#
# **Type:** `String` **Default:** `Each element of this collection should satisfy its own set of constraints.`
#
# The message that will be shown if validation fails and the internal constraint is an `AVD::Constraints::All`.
# See the [message](#message) argument for an example.
#
# ### message
#
# **Type:** `String` **Default:** `This value should satisfy at least one of the following constraints:`
#
# The intro that will be shown if validation fails.
# By default, it'll be followed by the list of messages from the internal [constraints](#constraints);
# configurable via the [include_internal_messages](#include_internal_messages) argument.
#
# For example, if the `grades` property in the example below fails to validate, the message will be:
#
# > This value should satisfy at least one of the following constraints: [1] This value is too short. It should have 3 items or more. [2] Each element of this collection should satisfy its own set of constraints.
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
# ```
# class Example
#   include AVD::Validatable
#
#   def initialize(@password : String, @grades : Array(Int32)); end
#
#   # Asserts the password contains an `#` or is at least 10 characters long.
#   @[Assert::AtLeastOneOf([
#     @[Assert::Regex(/#/)],
#     @[Assert::Size(10..)],
#   ])]
#   getter password : String
#
#   # Asserts the `grades` array contains at least 3 elements or
#   # that each element is greater than or equal to 5.
#   @[Assert::AtLeastOneOf([
#     @[Assert::Size(3..)],
#     @[Assert::All([
#       @[Assert::GreaterThanOrEqual(5)],
#     ])],
#   ])]
#   getter grades : Array(Int32)
# end
# ```
#
# NOTE: The annotation approach only supports two levels of nested annotations.
# Manually wire up the constraint via code if you require more than that.
class Athena::Validator::Constraints::AtLeastOneOf < Athena::Validator::Constraints::Composite
  DEFAULT_ERROR_MESSAGE = "This value should satisfy at least one of the following constraints:"
  AT_LEAST_ONE_OF_ERROR = "811994eb-b634-42f5-ae98-13eec66481b6"

  @@error_names = {
    AT_LEAST_ONE_OF_ERROR => "AT_LEAST_ONE_OF_ERROR",
  }

  getter include_internal_messages : Bool
  getter message_collection : String

  def initialize(
    constraints : AVD::Constraints::Composite::Type,
    @include_internal_messages : Bool = true,
    @message_collection : String = "Each element of this collection should satisfy its own set of constraints.",
    message : String = "This value should satisfy at least one of the following constraints:",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super constraints, message, groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::AtLeastOneOf) : Nil
      messages = [constraint.message]

      validator = self.context.validator

      constraint.constraints.each do |idx, item|
        violations = validator.validate value, [item]

        return if violations.empty?

        if constraint.include_internal_messages
          messages << String.build do |str|
            str << " [#{idx.to_i + 1}] "

            str << if item.is_a? AVD::Constraints::All
              constraint.message_collection
            else
              violations.first.message
            end
          end
        end
      end

      self.context.add_violation messages.join, AT_LEAST_ONE_OF_ERROR
    end
  end
end
