# Allows creating totally custom validation rules, assigning any violations to specific fields on your object.
# This process is achieved via using one or more _callback_ methods which will be invoked during the validation process.
#
# NOTE: The callback method itself does _fail_ or return any value.
# Instead it should directly add violations to the `AVD::ExecutionContextInterface` argument.
#
# ## Configuration
#
# ### Required Arguments
#
# #### callback
#
# **Type:** `AVD::Constraints::Callback::CallbackProc?` **Default:** `nil`
#
# The proc that should be invoked as the callback for this constraint.
#
# NOTE: If this argument is not supplied, the [callback_name](#callback_name) argument must be.
#
# #### callback_name
#
# **Type:** `String?` **Default:** `nil`
#
# The name of the method that should be invoked as the callback for this constraint.
#
# NOTE: If this argument is not supplied, the [callback](#callback) argument must be.
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
# The callback constraint supports two callback methods when validating objects, and one callback method when using the constraint directly.
#
# ### Instance Methods
#
# To define an instance callback method, apply the `@[Assert::Callback]` method to a public instance method defined within an object.
# This method should accept two arguments: the `AVD::ExecutionContextInterface` to which violations should be added,
# and the `AVD::Constraint@payload` from the related constraint.
#
# More than one callback method can exist on a type, and the method name does not have to be `validate`.
#
# ```
# class Example
#   include AVD::Validatable
#
#   SPAM_DOMAINS = ["fake.com", "spam.net"]
#
#   def initialize(@domain_name : String); end
#
#   @[Assert::Callback]
#   def validate(context : AVD::ExecutionContextInterface, payload : Hash(String, String)?) : Nil
#     # Validate that the `domain_name` is not spammy.
#     return unless SPAM_DOMAINS.includes? @domain_name
#
#     context
#       .build_violation("This domain name is not legit!")
#       .at_path("domain_name")
#       .add
#   end
# end
# ```
#
# ### Class Methods
#
# The callback method can also be defined as a class method.
# Since class methods do not have access to the related object instance, it is passed in as an argument.
#
# That argument is typed as `AVD::Constraints::Callback::Value` which exposes a `AVD::Constraints::Callback::Value#get`
# method that can be used as an easier syntax than `.as`.
#
# ```
# class Example
#   include AVD::Validatable
#
#   SPAM_DOMAINS = ["fake.com", "spam.net"]
#
#   @[Assert::Callback]
#   def self.validate(value : AVD::Constraints::Callback::Value, context : AVD::ExecutionContextInterface, payload : Hash(String, String)?) : Nil
#     # Get the object from the value, typed as our `Example` class.
#     object = value.get self
#
#     # Validate that the `domain_name` is not spammy.
#     return unless SPAM_DOMAINS.includes? object.domain_name
#
#     context
#       .build_violation("This domain name is not legit!")
#       .at_path("domain_name")
#       .add
#   end
#
#   def initialize(@domain_name : String); end
#
#   getter domain_name : String
# end
# ```
#
# ### Procs/Blocks
#
# When working with constraints in a non object context, a callback passed in as a proc/block.
# `AVD::Constraints::Callback::CallbackProc` alias can be used to more easily create a callback proc.
# `AVD::Constraints::Callback.with_callback` can be used to create a callback constraint, using the block as the callback proc.
# See the related types for more information.
#
# Proc/block based callbacks operate similarly to [Class Methods](#static-methods) in that they receive the value as an argument.
class Athena::Validator::Constraints::Callback(T) < Athena::Validator::Constraint
  # Convenience method for creating a `AVD::Constraints::Callback` with
  # the given *&block* as the callback.
  #
  # ```
  # # Instantiate a callback constraint, using the block as the callback
  # constraint = AVD::Constraints::Callback.with_callback do |value, context, payload|
  #   next if (value = value.get(Int32)).even?
  #
  #   context.add_violation "This value should be even."
  # end
  # ```
  def self.with_callback(**args, &block : T, AVD::ExecutionContextInterface, Hash(String, String)? ->) : AVD::Constraints::Callback
    new **args, callback: block
  end

  # Returns the name of the callback method this constraint should invoke.
  getter callback_name : String?

  # Returns the proc that this constraint should invoke.
  getter callback : Proc(T, AVD::ExecutionContextInterface, Hash(String, String)?, Nil)?

  def initialize(
    @callback : Proc(T, AVD::ExecutionContextInterface, Hash(String, String)?, Nil)? = nil,
    @callback_name : String? = nil,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    raise ArgumentError.new "either `callback` or `callback_name` must be provided." if @callback.nil? && @callback_name.nil?

    super "", groups, payload
  end

  # Ideally this would be in the validator itself, but this is needed to ensure
  # the value resoled to `T` correctly versus a union.
  protected def call(value : T, context : AVD::ExecutionContextInterface) : Nil
    @callback.not_nil!.call value, context, @payload
  end

  protected def call(value : _, context : AVD::ExecutionContextInterface) : Nil
    raise "BUG: #{value} #{T}."
  end

  struct Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::Callback) : Nil
      if value.is_a?(AVD::Validatable) && (name = constraint.callback_name) && (metadata = self.context.metadata) && (metadata.is_a?(AVD::Metadata::ClassMetadata))
        metadata.invoke_callback name, value, self.context, constraint.payload
      elsif !constraint.callback.nil?
        constraint.call value, self.context
      end
    end
  end
end
