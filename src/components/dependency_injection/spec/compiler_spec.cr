require "./spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe Athena::DependencyInjection do
  describe Athena::DependencyInjection::ServiceContainer do
    describe "compiler errors" do
      it "named argument is an array with a service reference that doesn't exist" do
        assert_error "Failed to register service 'klass'.  Could not resolve argument 'values : Array(Foo)' from named argument value '[\"@foo\"]'.", <<-CR
          record Foo

          @[ADI::Register(_values: ["@foo"])]
          class Klass
            def initialize(@values : Array(Foo)); end
          end
        CR
      end

      it "binding value is an array with a service reference that doesn't exist" do
        assert_error "Failed to register service 'klass'.  Could not resolve argument 'values : Array(Foo)' from binding value '[\"@foo\"]'.", <<-CR
          record Foo

          ADI.bind values, ["@foo"]

          @[ADI::Register]
          class Klass
            def initialize(@values : Array(Foo)); end
          end
        CR
      end

      it "service could not be auto registered due to an argument not resolving to any services" do
        assert_error "Failed to auto register service 'klass'.  Could not resolve argument 'service : MissingService'.", <<-CR
          class MissingService
          end

          @[ADI::Register]
          class Klass
            def initialize(@service : MissingService); end
          end
        CR
      end

      it "more than one service of a given type exist, but ivar name doesn't match any, nor is an alias defined" do
        assert_error "Failed to auto register service 'klass'.  Could not resolve argument 'service : Interface'.", <<-CR
          module Interface
          end

          @[ADI::Register]
          class One
            include Interface
          end

          @[ADI::Register]
          class Two
            include Interface
          end

          @[ADI::Register]
          class Klass
            def initialize(@service : Interface); end
          end
        CR
      end

      it "factory method is instance method" do
        assert_error "Failed to register service `klass`.  Factory method `double` within `Klass` is an instance method.", <<-CR
          @[ADI::Register(_value: 10, factory: "double")]
          class Klass
            def double(value : Int32) : self
              new value
            end

            def initialize(@value : Int32); end
          end
        CR
      end

      it "missing factory method" do
        assert_error "Failed to register service `klass`.  Factory method `double` within `Klass` does not exist.", <<-CR
          @[ADI::Register(_value: 10, factory: "double")]
          class Klass
            def self.triple(value : Int32) : self
              new value
            end

            def initialize(@value : Int32); end
          end
        CR
      end

      it "service based on type that has multiple generic arguments does not provide the correct amount of generic arguments" do
        assert_error "Failed to register service 'generic_service'.  Expected 2 generics types got 1.", <<-CR
          @[ADI::Register(Int32, name: "generic_service")]
          class GenericService(A, B)
            def initialize(@value : B); end
          end
        CR
      end

      it "service based on generic type does not provide any generic arguments" do
        assert_error "Failed to register service 'generic_service'.  Generic services must provide the types to use via the 'generics' field.", <<-CR
          @[ADI::Register(name: "generic_service")]
          class GenericService(T)
            def initialize(@value : T); end
          end
        CR
      end

      it "service based on generic type does not explicitly provide a name" do
        assert_error "Failed to register services for 'GenericService(T)'.  Generic services must explicitly provide a name.", <<-CR
          @[ADI::Register(generics: {Int32})]
          class GenericService(T)
            def initialize(@value : T); end
          end
        CR
      end

      it "multiple services are based on a type, but not all provide a name" do
        assert_error "Failed to register services for 'Klass'.  Services based on this type must each explicitly provide a name.", <<-CR
          class MissingService
          end

          @[ADI::Register(_id: 1, name: "one")]
          @[ADI::Register(_id: 2)]
          class Klass
            def initialize(@id : Int32); end
          end
        CR
      end

      it "a named argument is an array more than 2 levels deep" do
        assert_error "Failed to register service 'klass'.  Arrays more than two levels deep are not currently supported.", <<-CR
          @[ADI::Register(_values: [[[1]]])]
          class Klass
            def initialize(@values : Array(Array(Array(Int32)))); end
          end
        CR
      end

      it "assert the service has been removed from the container" do
        assert_error "undefined method 'service' for Athena::DependencyInjection::ServiceContainer", <<-CR
          @[ADI::Register]
          class Service
            property name : String = "Jim"
          end

          ADI::ServiceContainer.new.service
        CR
      end

      it "assert synthetic services are not public" do
        assert_error " protected method 'synthetic_service' called for Athena::DependencyInjection::ServiceContainer", <<-CR
          record SyntheticService, id : Int32 = 123

          module ManualService
            include ADI::PreArgumentsCompilerPass

            macro included
              macro finished
                {% verbatim do %}
                  {%
                    SERVICE_HASH["synthetic_service"] = {
                      public:    false,
                      synthetic: true,
                      service:   SyntheticService,
                      ivar_type: SyntheticService,
                      tags:      [] of Nil,
                      generics:  [] of Nil,
                      arguments: [] of Nil,
                    }
                  %}
                {% end %}
              end
            end
          end

          ADI::ServiceContainer.new.synthetic_service
        CR
      end

      it "a name must be supplied if using a NamedTupleLiteral tag" do
        assert_error "Failed to register service `tagged_service`.  Tags must be an ArrayLiteral or TupleLiteral, not NumberLiteral.", <<-CR
          @[ADI::Register(tags: 42)]
          class TaggedService
          end
        CR
      end

      it "tags can only be NamedTupleLiterals or StringLiterals" do
        assert_error "Failed to register service `tagged_service`.  A tag must be a StringLiteral or NamedTupleLiteral not BoolLiteral.", <<-CR
          @[ADI::Register(tags: [true])]
          class TaggedService
          end
        CR
      end

      it "a name must be supplied if using a NamedTupleLiteral tag" do
        assert_error "Failed to register service `tagged_service`.  All tags must have a name.", <<-CR
          @[ADI::Register(tags: [{priority: 42}])]
          class TaggedService
          end
        CR
      end
    end
  end
end
