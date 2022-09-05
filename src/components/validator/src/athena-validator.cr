require "json"

require "./constraint"
require "./constraint_validator"
require "./constraint_validator_factory"
require "./constraint_validator_factory_interface"
require "./constraint_validator_interface"
require "./execution_context"
require "./execution_context_interface"
require "./property_path"
require "./validatable"

require "./constraints/abstract_comparison"
require "./constraints/abstract_comparison_validator"
require "./constraints/*"
require "./exceptions/*"
require "./metadata/*"
require "./validator/*"
require "./violation/*"

# Convenience alias to make referencing `Athena::Validator` types easier.
alias AVD = Athena::Validator

# Used to apply constraints to instance variables and types via annotations.
#
# ```
# @[Assert::NotBlank]
# property name : String
# ```
# NOTE: Constraints, including custom ones, are automatically added to this namespace.
alias Assert = AVD::Annotations

# Athena's Validation component, `AVD` for short, adds an object/value validation framework to your project.
# The framework consists of `AVD::Constraint`s that describe some assertion; such as a string should be `AVD::Constraints::NotBlank`
# or that a value is `AVD::Constraints::GreaterThanOrEqual` another value.
# Constraints, along with a value, are then passed to an `AVD::ConstraintValidatorInterface` that actually performs the validation, using the data defined in the constraint.
# If the validator determines that the value is invalid in some way, it creates and adds an `AVD::Violation::ConstraintViolationInterface` to this runs' `AVD::ExecutionContextInterface`.
# The `AVD::Validator::ValidatorInterface` then returns an `AVD::Violation::ConstraintViolationListInterface` that contains all the violations.  The value can be considered valid if that list is empty.
#
# NOTE: See each type individually for more detailed information.
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/components/validator) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-validator:
#     github: athena-framework/validator
#     version: ~> 0.2.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-validator"`.
#
# ## Usage
#
# `Athena::Validator` comes with a set of common `AVD::Constraints` built in that any project could find useful.
# When used on its own, the `Athena::Validator.validator` method can be used to obtain an `AVD::Validator::ValidatorInterface` instance
# to validate a given value/object.
#
# ### Basics
#
# A validator accepts a value, and one or more `AVD::Constraint` to validate the value against.
# The validator then returns an `AVD::Violation::ConstraintViolationListInterface` that includes all the violations, if any.
#
# ```
# # Obtain a validator instance.
# validator = AVD.validator
#
# # Use the validator to validate a value.
# violations = validator.validate "foo", AVD::Constraints::NotBlank.new
#
# # The validator returns an empty list of violations, indicating the value is valid.
# violations.inspect # => Athena::Validator::Violation::ConstraintViolationList(@violations=[])
# ```
#
# In this case it returns an empty list of violations, meaning the value is valid.
#
# ```
# # Using the validator instance from the previous example
# violations = validator.validate "", AVD::Constraints::NotBlank.new
#
# violations.inspect # =>
# # Athena::Validator::Violation::ConstraintViolationList(
# #   @violations=[
# #     Athena::Validator::Violation::ConstraintViolation(
# #       @cause=nil,
# #       @code="0d0c3254-3642-4cb0-9882-46ee5918e6e3",
# #       @constraint=#<Athena::Validator::Constraints::NotBlank:0x7f8a7291fed0
# #         @allow_nil=false,
# #         @groups=["default"],
# #         @message="This value should not be blank.",
# #         @payload=nil>,
# #       @invalid_value_container=Athena::Validator::ValueContainer(String)(@value=""),
# #       @message="This value should not be blank.",
# #       @message_template="This value should not be blank.",
# #       @parameters={"{{ value }}" => ""},
# #       @plural=nil,
# #       @property_path="",
# #       @root_container=Athena::Validator::ValueContainer(String)(@value="")
# #     )
# #   ]
# )
#
# # Both the ConstraintViolationList and ConstraintViolation implement a `#to_s` method.
# puts violations # =>
# # :
# #   This value should not be blank. (code: 0d0c3254-3642-4cb0-9882-46ee5918e6e3)
# ```
#
# However in the case of the value _NOT_ being valid, the list includes all of the `AVD::Violation::ConstraintViolationInterface`s produced during this run.
# Each violation includes some metadata; such as the related constraint that failed, a machine readable code, a human readable message, any parameters
# that should be used to render that message, etc.  The extra context allows for a lot of flexibility; both in terms of how the error could be rendered or handled.
#
# By default, in addition to any constraint specific arguments, the majority of the constraints have three optional arguments: `message`, `groups`, and `payload`.
#
# * The `message` argument represents the message that should be used if the value is found to not be valid.
# The message can also include placeholders, in the form of `{{ key }}`, that will be replaced when the message is rendered.
# Most commonly this includes the invalid value itself, but some constraints have additional placeholders.
# * The `payload` argument can be used to attach any domain specific data to the constraint; such as attaching a severity with each constraint
# to have more serious violations be handled differently.
# * The `groups` argument can be used to run a subset of the defined constraints.  More on this in the [Validation Groups](#validation-groups) section.
#
# ```
# validator = AVD.validator
#
# # Instantiate a constraint with a custom message, using a placeholder.
# violations = validator.validate -4, AVD::Constraints::PositiveOrZero.new message: "{{ value }} is not a valid age.  A user cannot have a negative age."
#
# puts violations # =>
# # -4:
# #   -4 is not a valid age.  A user cannot have a negative age. (code: e09e52d0-b549-4ba1-8b4e-420aad76f0de)
# ```
# Customizing the message can be a good way for those consuming the errors to determine _WHY_ a given value is not valid.
#
# ### Validating Objects
#
# Validating arbitrary values against a set of arbitrary constraints can be useful in smaller applications and/or for one off use cases.
# However to keep in line with our Object Oriented Programming (OOP) principles, we can also validate objects.  The object could be either a struct or a class.
# The only requirements are that the object includes a specific module, `AVD::Validatable`, and specifies which properties should be validated and against what constraints.
# The easiest/most common way to do this is via annotations and the `Assert` alias.
#
# ```
# # Define a class that can be validated.
# class User
#   include AVD::Validatable
#
#   def initialize(@name : String, @age : Int32? = nil); end
#
#   # Specify that we want to assert that the user's name is not blank.
#   # Multiple constraints can be defined on a single property.
#   @[Assert::NotBlank]
#   getter name : String
#
#   # Arguments to the constraint can be used normally as well.
#   # The constraint's default argument can also be supplied positionally: `@[Assert::GreaterThan(0)]`.
#   @[Assert::NotNil(message: "A user's age cannot be null")]
#   getter age : Int32?
# end
#
# # Obtain a validator instance.
# validator = AVD.validator
#
# # Validate a user instance, notice we're not passing in any constraints.
# validator.validate(User.new("Jim", 10)).empty? # => true
# validator.validate User.new "", 10             # =>
# # Object(User).name:
# #   This value should not be blank. (code: 0d0c3254-3642-4cb0-9882-46ee5918e6e3)
# ```
#
# Notice that in this case we do not need to supply the constraints to the `#validate` method.
# This is because the validator is able to extract them from the annotations on the properties.
# An array of constraints can still be supplied, and will take precedence over the constraints defined within the type.
#
# NOTE: By default if a property's value is another object, the sub object will not be validated.
# use the `AVD::Constraints::Valid` constraint if you wish to also validate the sub object.
# This also applies to arrays of objects.
#
# Another important thing to point out is that no custom DSL is required to define these constraints.
# `Athena::Validator` is intended to be a generic validation solution that could be used outside of the [Athena](https://github.com/athena-framework) ecosystem.
# However, in order to be able to use the annotation based approach, you need to be able to apply the annotations to the underlying properties.
# If this is not possible due to how a specific type is implemented, or if you just don't like the annotation syntax, the type can also be configured via code.
#
# ```
# # Define a class that can be validated.
# class User
#   include AVD::Validatable
#
#   # This class method is invoked when building the metadata associated with a type,
#   # and can be used to manually wire up the constraints.
#   def self.load_metadata(metadata : AVD::Metadata::ClassMetadata) : Nil
#     metadata.add_property_constraint "name", AVD::Constraints::NotBlank.new
#   end
#
#   def initialize(@name : String); end
#
#   getter name : String
# end
#
# # Obtain a validator instance.
# validator = AVD.validator
#
# # Validate a user instance, notice we're not passing in any constraints.
# validator.validate(User.new("Jim")).empty? # => true
# validator.validate User.new ""             # =>
# # Object(User).name:
# #   This value should not be blank. (code: 0d0c3254-3642-4cb0-9882-46ee5918e6e3)
# ```
#
# The metadata for each type is lazily loaded when an instance of that type is validated, and is only built once.
# See `AVD::Metadata::ClassMetadata` for some additional ways to register property constraints.
#
# #### Getters
#
# Constraints can also be applied to getter methods of an object.
# This allows for dynamic validations based on the return value of the method.
# For example, say we wanted to assert that a user's name is not the same as their password.
#
# ```
# class User
#   include AVD::Validatable
#
#   property name : String
#   property password : String
#
#   def initialize(@name : String, @password : String); end
#
#   @[Assert::IsTrue(message: "Your password cannot be the same as your name.")]
#   def is_safe_password? : Bool
#     @name != @password
#   end
# end
#
# validator = AVD.validator
#
# user = User.new "foo", "foo"
#
# validator.validate(user).empty? # => false
#
# user.password = "bar"
#
# validator.validate(user).empty? # => true
# ```
#
# ### Custom Constraints
#
# If the built in `AVD::Constraints` are not sufficient to handle validating a given value/object; custom ones can be defined.
# Let's make a new constraint that asserts a string contains only alphanumeric characters.
#
# This is accomplished by first defining a new class within the `AVD::Constraints` namespace that inherits from `AVD::Constraint`.
# Then define a `Validator` struct within our constraint that inherits from `AVD::ConstraintValidator` that actually implements the validation logic.
#
# ```
# class AVD::Constraints::AlphaNumeric < AVD::Constraint
#   # (Optional) A unique error code can also be defined to provide a machine readable identifier for a specific error.
#   NOT_ALPHANUMERIC_ERROR = "1a83a8bd-ff79-4d5c-96e7-86d0b25b8a09"
#
#   # (Optional) Allows using the `.error_message(code : String) : String` method with this constraint.
#   @@error_names = {
#     NOT_ALPHANUMERIC_ERROR => "NOT_ALPHANUMERIC_ERROR",
#   }
#
#   # Define an initializer with our default message, and any additional arguments specific to this constraint.
#   def initialize(
#     message : String = "This value should contain only alphanumeric characters.",
#     groups : Array(String) | String | Nil = nil,
#     payload : Hash(String, String)? = nil
#   )
#     super message, groups, payload
#   end
#
#   # Define the validator within our constraint that'll contain our validation logic.
#   class Validator < AVD::ConstraintValidator
#     # Define our validate method that accepts the value to be validated, and the constraint.
#     #
#     # Overloads can be used to filter values of specific types.
#     def validate(value : _, constraint : AVD::Constraints::AlphaNumeric) : Nil
#       # Custom constraints should ignore nil and empty values to allow
#       # other constraints (NotBlank, NotNil, etc.) take care of that
#       return if value.nil? || value == ""
#
#       # We'll cast the value to a string,
#       # alternatively we could just ignore non `String?` values.
#       value = value.to_s
#
#       # If all the characters of this string are alphanumeric, then it is valid
#       return if value.each_char.all? &.alphanumeric?
#
#       # Otherwise, it is invalid and we need to add a violation,
#       # see `AVD::ExecutionContextInterface` for additional information.
#       self.context.add_violation constraint.message, NOT_ALPHANUMERIC_ERROR, value
#     end
#   end
# end
#
# puts AVD.validator.validate "$", AVD::Constraints::AlphaNumeric.new # =>
# # $:
# #   This value should contain only alphanumeric characters. (code: 1a83a8bd-ff79-4d5c-96e7-86d0b25b8a09)
# ```
#
# NOTE: The constraint _MUST_ be defined within the `AVD::Constraints` namespace for implementation reasons.  This may change in the future.
#
# We are now able to use this constraint as we would one of the built in ones;
# either by manually instantiating it, or applying an `@[Assert::AlphaNumeric]` annotation to a property.
#
# See `AVD::ConstraintValidatorInterface` for more information on custom validators.
#
# ### Validation Groups
#
# By default when validating an object, all constraints defined on that type will be checked.
# However, in some cases you may only want to validate the object against _some_ of those constraints.
# This can be accomplished via assigning each constraint to a validation group, then apply validation against one specific group of constraints.
#
# For example, using our `User` class from earlier, say we only want to validate certain properties when the user is first created.
# To do this we can utilize the `groups` argument that all constraints have.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@email : String, @password : String, @city : String); end
#
#   @[Assert::Email(groups: "create")]
#   getter email : String
#
#   @[Assert::NotBlank(groups: "create")]
#   @[Assert::Size(7.., groups: "create")]
#   getter password : String
#
#   @[Assert::Size(2..)]
#   getter city : String
# end
#
# user = User.new "george@dietrich.app", "monkey123", ""
#
# # Validate the user object, but only for those in the "create" group,
# # if no groups are supplied, then all constraints in the "default" group will be used.
# violations = AVD.validator.validate user, groups: "create"
#
# # There are no violations since the city's size is not validated since it's not in the "create" group.
# violations.empty? # => true
# ```
#
# See `AVD::Constraint@validation-groups` for some expanded information.
#
# ### Sequential Validation
#
# By default, all constraints are validated in a single "batch".  I.e. all constraints within the provided group(s) are validated, without regard
# to if the previous/next constraint is/was (in)valid.  However, an `AVD::Constraints::GroupSequence` can be used to validate batches of constraints in steps.
# I.e. validate the first "batch" of constraints, and only advance to the next batch if all constraints in that step are valid.
#
# ```
# @[Assert::GroupSequence("User", "Secondary")]
# class User
#   include AVD::Validatable
#
#   @[Assert::NotBlank]
#   getter username : String
#
#   @[Assert::NotBlank(groups: "Secondary")]
#   getter password : String
#
#   def initialize(@username : String, @password : String); end
# end
#
# # Instantiate a new `User` object where both properties are invalid.
# user = User.new "", ""
#
# # Notice there is only one violation since there was a violation in the `User` group,
# # it did not advance to the `Secondary` group.
# AVD.validator.validate user # =>
# # Object(User).username:
# #   This value should not be blank. (code: 0d0c3254-3642-4cb0-9882-46ee5918e6e3)
# ```
#
# #### Group Sequence Providers
#
# The `AVD::Constraints::GroupSequence` can be a useful tool for creating efficient validations, but it is quite limiting since the sequence is static on the type.
# If more flexibility is required the `AVD::Constraints::GroupSequence::Provider` module can be included into a type.
# The module allows the object to return the sequence it should use dynamically at runtime.
#
# ```
# class User
#   include AVD::Validatable
#   include AVD::Constraints::GroupSequence::Provider
#
#   # ...
#
#   def group_sequence : Array(Array(String) | String) | AVD::Constraints::GroupSequence
#     # Build out and return the sequence `self` should use.
#   end
# end
# ```
#
# Alternatively, if you only want to apply constraints sequentially on a single property,
# the `AVD::Constraints::Sequentially` constraint can be used to do this in a simpler way.
#
# NOTE: See the related types for more detailed information.
module Athena::Validator
  VERSION = "0.2.1"

  # :nodoc:
  #
  # Default namespace for constraint annotations.
  #
  # NOTE: Constraints, including custom ones, are automatically added to this namespace.
  module Annotations; end

  # Contains all of the built in `AVD::Constraint`s.
  # See each individual constraint for more information.
  # The `Assert` alias is used to apply these constraints via annotations.
  module Constraints; end

  # Contains all custom exceptions defined within `Athena::Validator`.
  module Exceptions; end

  # Contains types used to store metadata associated with a given `AVD::Validatable` instance.
  #
  # Most likely you won't have to work any of these directly.
  # However if you are adding constraints manually to properties using the `self.load_metadata` method,
  # you should be familiar with `AVD::Metadata::ClassMetadata`.
  module Metadata; end

  # Contains types related to the validator itself.
  module Validator; end

  # Contains types related to constraint violations.
  module Violation; end

  # :nodoc:
  abstract struct Container; end

  # :nodoc:
  record ValueContainer(T) < Container, value : T do
    def value_type : T.class
      T
    end

    def ==(other : AVD::Container) : Bool
      @value == other.value
    end
  end

  # Returns a new `AVD::Validator::ValidatorInterface`.
  #
  # ```
  # validator = AVD.validator
  #
  # validator.validate "foo", AVD::Constraints::NotBlank.new
  # ```
  def self.validator : AVD::Validator::ValidatorInterface
    AVD::Validator::RecursiveValidator.new
  end
end
