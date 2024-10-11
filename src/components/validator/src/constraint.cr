# `Athena::Validator` validates values/objects against a set of constraints, i.e. rules.
# Each constraint makes an assertive statement that some condition is true.
# Given a value, a constraint will tell you if that value adheres to the rules of the constraint.
# An example of this could be asserting a value is not blank, or greater than or equal to another value.
#
# It's important to note a constraint does not implement the validation logic itself.
# Instead, this is handled via an `AVD::ConstraintValidator` as defined via `#validated_by`.
# Having this abstraction allows for better reusability and testability.
#
# `Athena::Validator` comes with a set of common constraints built in.
# See the individual types within `AVD::Constraints` for more information.
#
# ## Usage
#
# A constraint can be instantiated and passed to a validator directly:
#
# ```
# # An array of constraints can also be passed.
# AVD.validator.validate "", AVD::Constraints::NotBlank.new
# ```
#
# Constraint annotation(s) can also be applied to instance variables to assert the value of that property adheres to the constraint.
#
# ```
# class Example
#   include AVD::Validatable
#
#   def initialize(@name : String); end
#
#   # More than one constraint can be applied to a property.
#   @[Assert::NotBlank]
#   property name : String
# end
#
# # Constraints are extracted from the annotations.
# # An array can also be passed to validate against that list instead.
# AVD.validator.validate Example.new("Jim")
# ```
#
# Constraints can also be added manually via code by defining an `self.load_metadata(metadata : AVD::Metadata::ClassMetadata) : Nil`
# method and adding the constraints directly to the `AVD::Metadata::ClassMetadata` instance.
#
# ```
# # This class method is invoked when building the metadata associated with a type,
# # and can be used to manually wire up the constraints.
# def self.load_metadata(metadata : AVD::Metadata::ClassMetadata) : Nil
#   metadata.add_property_constraint "name", AVD::Constraints::NotBlank.new
# end
# ```
#
# The metadata for each type is lazily loaded when an instance of that type is validated, and is only built once.
#
# ## Arguments
#
# While most constraints can be instantiated with an argless constructor,they do have a set of optional arguments.
# * The `message` argument represents the message that should be used if the value is found to not be valid.
# The message can also include placeholders, in the form of `{{ key }}`, that will be replaced when the message is rendered.
# Most commonly this includes the invalid value itself, but some constraints have additional placeholders.
# * The `payload` argument can be used to attach any domain specific data to the constraint; such as attaching a severity with each constraint
# to have more serious violations be handled differently.  See the [Payload][Athena::Validator::Constraint--payload] section.
# * The `groups` argument can be used to run a subset of the defined constraints.  More on this in the [Validation Groups][Athena::Validator::Constraint--validation-groups] section.
#
# For example:
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
# ### Default Argument
#
# The first argument of the constructor is known as the default argument.
# This argument is special when using the annotation based approach in that it can be supplied as a positional argument within the annotation.
#
# For example the default argument for `AVD::Constraints::GreaterThan` is the value that the value being validated should be compared against.
#
# Thus:
#
# ```
# @[Assert::GreaterThan(0)]
# property age : Int32
# ```
#
# Is equivalent to:
#
# ```
# @[Assert::GreaterThan(value: 0)]
# property age : Int32
# ```
#
# NOTE: Only the first argument can be supplied positionally, all other arguments must be provided as named arguments within the annotation.
#
# ### Message Plurality
#
# `Athena::Validator` has very basic support for pluralizing constraint `#message`s via `AVD::Violation::ConstraintViolationInterface#plural`.
#
# For example the `#message` could have different versions based on the plurality of the violation.
# Currently this only supports two contexts: singular (1/nil) and plural (2+).
#
# Multiple messages, separated by a `|`, can be included as part of an `AVD::Constraint` message.
# For example from `AVD::Constraints::Size`:
#
# `min_message : String = "This value is too short. It should have {{ limit }} {{ type }} or more.|This value is too short. It should have {{ limit }} {{ type }}s or more."`
#
# If violations' `#plural` method returns `1` (or `nil`) the first message will be used.  If `#plural` is `2` or more, the latter message will be used.
#
# TODO: Support more robust translations; like language or multiple pluralities.
#
# ### Payload
#
# The `payload` argument defined on every `AVD::Constraint` type can be used to store custom domain specific information with a constraint.
# This data can later be retrieved off of an `AVD::Violation::ConstraintViolationInterface`.
# An example use case for this could be mapping a "severity" to a CSS class based on how important each specific constraint is.
#
# ```
# class User
#   include AVD::Validatable
#
#   def initialize(@email : String, @password : String); end
#
#   @[Assert::NotBlank(payload: {"severity" => "error"})]
#   getter email : String
#
#   @[Assert::NotBlank(payload: {"severity" => "warning"})]
#   getter password : String
# end
#
# violations = AVD.validator.validate User.new "", ""
#
# # Use this when rendering HTML, or JSON to allow dynamically customizing the response object.
# violations[0].constraint.payload # => {"severity" => "error"}
# violations[1].constraint.payload # => {"severity" => "warning"}
# ```
#
# ## Validation Groups
#
# The `groups` argument defined on every `AVD::Constraint` type can be used to run a subset of validations.
#
# For example, say we only want to validate certain properties when the user is first created:
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
# user = User.new "contact@athenaframework.org", "monkey123", ""
#
# # Validate the user object, but only for those in the "create" group,
# # if no groups are supplied, then all constraints in the "default" group will be used.
# violations = AVD.validator.validate user, groups: "create"
#
# # There are no violations since the city's size is not validated since it's not in the "create" group.
# violations.empty? # => true
# ```
#
# Using this configuration, there are three groups at play within the `User` class:
# 1. `default` - Contains constraints in the current type, and subtypes, that belong to no other group.  I.e. `city`.
# 1. `User` - In this example, equivalent to all constraints in the `default` group.  See `AVD::Constraints::GroupSequence`, and the note below.
# 1. `create` - A custom group that only contains the constraints explicitly associated with it.  I.e. `email`, and `password`.
#
# NOTE: When validating _just_ the `User` object, the `default` group is equivalent to the `User` group.
# However, if the `User` object has other embedded types using the `AVD::Constraints::Valid` constraint, then validating the `User` object with the `User`
# group would only validate constraints that are explicitly in the `User` group within the embedded types.
#
# By default, all constraints are validated in a single "batch".  I.e. all constraints within the provided group(s) are validated, without regard
# to if the previous/next constraint is/was (in)valid.  However, an `AVD::Constraints::GroupSequence` can be used to validate batches of constraints in steps.
# I.e. validate the first "batch" of constraints, and only advance to the next batch if all constraints in that step are valid.
#
# NOTE: The payload is not used with the framework itself.
#
# ## Custom Constraints
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
#     payload : Hash(String, String)? = nil,
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
# NOTE:  The `AVD::Constraints::Compound` constraint can be used to create a constraint that consists of one or more other constraints.
#
abstract class Athena::Validator::Constraint
  # The group that `self` is a part of if no other group(s) are explicitly defined.
  DEFAULT_GROUP = "default"

  @@error_names = Hash(String, String).new

  # Returns the name of the provided *error_code*.
  def self.error_name(error_code : String) : String
    @@error_names[error_code]? || raise AVD::Exception::InvalidArgument.new "The error code '#{error_code}' does not exist for constraint of type '#{self}'."
  end

  # Returns the message that should be rendered if `self` is found to be invalid.
  #
  # NOTE: Some subtypes do not use this and instead define multiple message
  # properties in order to support more specific error messages.
  getter message : String

  # Returns any domain specific data associated with `self`.
  getter payload : Hash(String, String)?

  # This isn't set directly as a property such that we can somewhat tell if it's been customized or not.
  # E.g. so that the composite constraint knows if it needs to apply its groups to it or not
  @groups : Array(String)? = nil

  def initialize(@message : String, groups : Array(String) | String | Nil = nil, @payload : Hash(String, String)? = nil)
    unless groups.nil?
      @groups = case groups
                when Array  then groups
                when String then [groups]
                end
    end
  end

  # Sets the validation groups `self` is a part of.
  def groups=(@groups : Array(String))
  end

  # Returns the validation groups `self` is a part of.
  def groups : Array(String)
    @groups ||= [DEFAULT_GROUP]
  end

  # Adds the provided *group* to `#groups` if `self` is in the `AVD::Constraint::DEFAULT_GROUP`.
  def add_implicit_group(group : String) : Nil
    if self.groups.includes?(DEFAULT_GROUP) && !self.groups.includes?(group)
      self.groups << group
    end
  end

  # Returns the `AVD::ConstraintValidator.class` that should handle validating `self`.
  abstract def validated_by : AVD::ConstraintValidator.class

  macro inherited
    {% unless @type.abstract? %}
      # See `{{@type.id}}`.
      annotation ::Athena::Validator::Annotations::{{@type.name(generic_args: false).split("::").last.id}}; end

      # :inherit:
      def validated_by : AVD::ConstraintValidator.class
        Validator
      end
    {% end %}
  end
end
