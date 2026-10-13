# Integrates the Validator component with the [dependency injection](/DependencyInjection/) component, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-validator/bundle` to register the bundle; it does not require any configuration:
#
# ```
# require "athena"
# require "athena-validator/bundle"
# ```
#
# The bundle registers the `validator` service, which may be injected via `AVD::Validator::ValidatorInterface`:
#
# ```
# @[ADI::Register]
# class ArticleImporter
#   def initialize(@validator : AVD::Validator::ValidatorInterface); end
#
#   def import(article : Article) : Nil
#     violations = @validator.validate article
#
#     # ...
#   end
# end
# ```
#
# When registered, the framework also uses it to validate request bodies, see [ATHR::RequestBody](/Framework/Controller/ValueResolvers/RequestBody/).
#
# ## Service Constraint Validators
#
# Constraint validators that need other services can inherit from `AVD::ServiceConstraintValidator` and be registered as a service.
# The bundle tags these services with `validator.constraint_validator`, and provides them to the validator's `AVD::ConstraintValidatorFactoryInterface`:
#
# ```
# class Athena::Validator::Constraints::UniqueEmail < AVD::Constraint
#   # ...
#
#   @[ADI::Register]
#   class Validator < AVD::ServiceConstraintValidator
#     def initialize(@user_repository : UserRepository); end
#
#     # :inherit:
#     def validate(value : _, constraint : AVD::Constraints::UniqueEmail) : Nil
#       # ...
#     end
#   end
# end
# ```
@[ADI::Bundle("validation")]
struct Athena::Validator::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  # :nodoc:
  module Schema
    include ADI::Extension::Schema
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            AUTO_CONFIGURATIONS[Athena::Validator::ServiceConstraintValidator] = {
              tags: ["validator.constraint_validator"],
            }

            SERVICE_HASH[validator_factory_id = "validator_constraint_validator_factory"] = {
              class:      Athena::Validator::ConstraintValidatorFactory,
              parameters: {
                constraint_validators: {value: "!validator.constraint_validator"},
              },
            }

            ALIASES[Athena::Validator::ConstraintValidatorFactoryInterface] = [
              {id: validator_factory_id, public: false},
            ]

            SERVICE_HASH[validator_id = "validator"] = {
              class: Athena::Validator::Validator::RecursiveValidator,
            }

            ALIASES[Athena::Validator::Validator::ValidatorInterface] = [
              {id: validator_id, public: false},
            ]
          %}
        {% end %}
      end
    end
  end
end
