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

module Athena; end

# Provides a robust object/value validation framework.
module Athena::Validator
  VERSION = "0.3.4"

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
