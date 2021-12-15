# :nodoc:
annotation Athena::Validator::Annotations::GroupSequence; end

# Allows validating your `AVD::Constraint@validation-groups` in steps.
# I.e. only continue to the next group if all constraints in the first group are valid.
#
# ```
# @[Assert::GroupSequence("User", "strict")]
# class User
#   include AVD::Validatable
#
#   @[Assert::NotBlank]
#   property name : String
#
#   @[Assert::NotBlank]
#   property password : String
#
#   def initialize(@name : String, @password : String); end
#
#   @[Assert::IsTrue(message: "Your password cannot be the same as your name.", groups: "strict")]
#   def is_safe_password? : Bool
#     @name != @password
#   end
# end
# ```
#
# In this case, it'll validate the `name` and `password` properties are not blank before validating they are not the same.
# If either property is blank, the `is_safe_password?` validation will be skipped.
#
# NOTE: The `default` group is not allowed as part of a group sequence.
#
# NOTE: Calling `validate` with a group in the sequence, such as `strict`, will
# cause violations to _ONLY_ use that group and not all groups within the sequence.
# This is because the group sequence is now referred to as the `default` group.
#
# See `AVD::Constraints::GroupSequence::Provider` for a way to dynamically determine the sequence an object should use.
struct Athena::Validator::Constraints::GroupSequence
  getter groups : Array(String | Array(String))

  def self.new(groups : Array(String))
    new groups.map &.as(String | Array(String))
  end

  def initialize(@groups : Array(String | Array(String))); end

  # `AVD::Constraints::GroupSequence`s can be a good way to create efficient validations.
  # However, since the sequence is static, it is not a very flexible solution.
  #
  # Group sequence providers allow the sequence to be dynamically determined at runtime.
  # This allows running specific validations only when the object is in a specific state,
  # such as validating a "registered" user differently than a non-registered user.
  #
  # ```
  # class User
  #   include AVD::Validatable
  #
  #   # Include the interface that informs the validator this object will provide its sequence.
  #   include AVD::Constraints::GroupSequence::Provider
  #
  #   @[Assert::NotBlank]
  #   property name : String
  #
  #   # Only validate the `email` property if the `#group_sequence` method includes "registered"
  #   # Which can be determined using the current state of the object.
  #   @[Assert::Email(groups: "registered")]
  #   @[Assert::NotBlank(groups: "registered")]
  #   property email : String?
  #
  #   def initialize(@name : String, @email : String); end
  #
  #   # Define a method that returns the sequence.
  #   def group_sequence : Array(String | Array(String)) | AVD::Constraints::GroupSequence
  #     # When returning a 1D array, if there is a vaiolation in any group
  #     # the rest of the groups are not validated.  E.g. if `User` fails,
  #     # `registered` and `api` are not validated:
  #     return ["User", "registered", "api"]
  #
  #     # When returning a nested array, all groups included in each array are validated.
  #     # E.g. if `User` fails, `Premium` is also validated (and you'll get its violations),
  #     # but `api` will not be validated
  #     return [["User", "registered"], "api"]
  #   end
  # end
  # ```
  #
  # See `AVD::Constraints::Sequentially` for a more straightforward method of applying constraints sequentially on a single property.
  module Provider
    abstract def group_sequence : Array(String | Array(String)) | AVD::Constraints::GroupSequence
  end
end
