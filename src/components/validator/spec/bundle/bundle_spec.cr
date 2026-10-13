require "../spec_helper"
require "athena-dependency_injection"
require "../../src/bundle/bundle"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "../spec_helper.cr"
    require "../../src/bundle.cr"

    @[ADI::Register(public: true)]
    class ValidatorConsumer
      def initialize(@validator : AVD::Validator::ValidatorInterface); end
    end
  CR
end

describe AVD::Bundle, tags: "compiled" do
  it "registers the validator services" do
    assert_compiles <<-'CR'
      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH

            validator = sh["validator"]
            validator_factory = sh["validator_constraint_validator_factory"]
          %}
          ASPEC.compile_time_assert(\{{ validator["class"].resolve == Athena::Validator::Validator::RecursiveValidator }}, "Expected validator class to be Athena::Validator::Validator::RecursiveValidator")
          ASPEC.compile_time_assert(\{{ validator_factory["class"].resolve == Athena::Validator::ConstraintValidatorFactory }}, "Expected validator factory class to be Athena::Validator::ConstraintValidatorFactory")
        end
      end
    CR
  end

  it "wires the services together via their interfaces" do
    assert_compiles <<-'CR'
      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["validator_consumer"]["parameters"]["validator"]["value"].stringify == "validator" }}, "Expected the validator to be injected via AVD::Validator::ValidatorInterface")
          ASPEC.compile_time_assert(\{{ sh["validator"]["parameters"]["validator_factory"]["value"].stringify == "validator_constraint_validator_factory" }}, "Expected the validator factory to be injected via AVD::ConstraintValidatorFactoryInterface")
        end
      end
    CR
  end

  it "provides service constraint validators to the validator factory" do
    assert_compiles <<-'CR'
      @[ADI::Register]
      class ServiceValidator < AVD::ServiceConstraintValidator; end

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["service_validator"]["tags"]["validator.constraint_validator"] != nil }}, "Expected service constraint validators to be tagged 'validator.constraint_validator'")
          ASPEC.compile_time_assert(\{{ sh["validator_constraint_validator_factory"]["parameters"]["constraint_validators"]["value"].stringify == %([service_validator]) }}, "Expected the service constraint validators to be injected into the validator factory")
        end
      end
    CR
  end

  it "validates via service constraint validators" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "../../src/bundle"

      @[ADI::Register]
      class ForbiddenWords
        def includes?(value : String) : Bool
          value == "forbidden"
        end
      end

      class AVD::Constraints::NotForbidden < AVD::Constraint
        def initialize(
          message : String = "This value is forbidden.",
          groups : Array(String) | String | Nil = nil,
          payload : Hash(String, String)? = nil,
        )
          super message, groups, payload
        end

        @[ADI::Register]
        class Validator < AVD::ServiceConstraintValidator
          def initialize(@forbidden_words : ForbiddenWords); end

          def validate(value : String, constraint : AVD::Constraints::NotForbidden) : Nil
            return unless @forbidden_words.includes? value

            self.context.add_violation constraint.message
          end
        end
      end

      @[ADI::Register(public: true)]
      class ValidatorConsumer
        getter validator : AVD::Validator::ValidatorInterface

        def initialize(@validator : AVD::Validator::ValidatorInterface); end
      end

      validator = ADI.container.validator_consumer.validator

      raise "Expected 'allowed' to be valid" unless validator.validate("allowed", AVD::Constraints::NotForbidden.new).empty?
      raise "Expected 'forbidden' to be invalid" unless validator.validate("forbidden", AVD::Constraints::NotForbidden.new).size == 1
    CR
  end
end
