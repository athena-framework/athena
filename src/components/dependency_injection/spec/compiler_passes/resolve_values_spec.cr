require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: %(require "../spec_helper.cr"), postamble: "ADI::ServiceContainer.new"
end

module ResolveValuePriorityInterface; end

@[ADI::Register]
@[ADI::AsAlias("my_string_alias")]
record ServicePriorityOne do
  include ResolveValuePriorityInterface
end

@[ADI::Register]
record ServicePriorityTwo do
  include ResolveValuePriorityInterface
end

@[ADI::Register]
@[ADI::AsAlias(ResolveValuePriorityInterface)]
record ServicePriorityFour do
  include ResolveValuePriorityInterface
end

@[ADI::Register]
record ServicePriorityThree

@[ADI::Register(_ann_bind: 1000, public: true)]
@[ADI::Autoconfigure(bind: {ann_bind: 800, global_bind: 800, auto_configure_bind: 800})]
class ValuePriorityService
  getter ann_bind, global_bind, auto_configure_bind, default_value, nilable_type

  def initialize(
    ann_bind : Int32,
    global_bind : Int32,
    auto_configure_bind : Int32,
    nilable_type : Int32?,
    default_value : Int32 = 700,
  )
    ann_bind.should eq 1000
    global_bind.should eq 900
    auto_configure_bind.should eq 800
    nilable_type.should be_nil
    default_value.should eq 700
  end
end

ADI.bind ann_bind : Int32, 900
ADI.bind global_bind : Int32, 900

@[ADI::Register(_alias_overridden_by_ann_bind: "@service_priority_one", _alias_service_via_string_alias: "@my_string_alias", public: true)]
@[ADI::Autoconfigure(bind: {alias_overridden_by_auto_configure_bind: "@service_priority_two"})]
class ServiceValuePriorityService
  getter explicit_auto_wire, interface_service_matches_name, default_alias, alias_overridden_by_ann_bind

  def initialize(
    explicit_auto_wire : ServicePriorityThree,
    service_priority_two : ResolveValuePriorityInterface,
    default_alias : ResolveValuePriorityInterface,
    alias_overridden_by_ann_bind : ResolveValuePriorityInterface,
    alias_overridden_by_global_bind : ResolveValuePriorityInterface,
    alias_overridden_by_auto_configure_bind : ResolveValuePriorityInterface,

    # Validates container rewrites the alias service ID to the real underlying service ID
    alias_service_via_string_alias : ResolveValuePriorityInterface,
  )
    explicit_auto_wire.should be_a ServicePriorityThree
    service_priority_two.should be_a ServicePriorityTwo
    default_alias.should be_a ServicePriorityFour
    alias_overridden_by_ann_bind.should be_a ServicePriorityOne
    alias_overridden_by_global_bind.should be_a ServicePriorityOne
    alias_overridden_by_auto_configure_bind.should be_a ServicePriorityTwo
    alias_service_via_string_alias.should be_a ServicePriorityOne
  end
end

ADI.bind alias_overridden_by_global_bind : ResolveValuePriorityInterface, "@service_priority_one"

@[ADI::Register(_value: false, public: true)]
record BoolExplicitArgumentService, value : Bool

module LocatorServiceInterface
  abstract def name : String
end

@[ADI::Register]
class LocatorLazyService
  include LocatorServiceInterface

  class_getter? instantiated : Bool = false

  def initialize
    @@instantiated = true
  end

  def name : String
    "lazy"
  end
end

@[ADI::Register]
@[ADI::AsAlias("locator_aliased_service_alias")]
class LocatorAliasedService
  include LocatorServiceInterface

  def name : String
    "aliased"
  end
end

@[ADI::Register(public: true, _services: {"lazy" => "@locator_lazy_service", "aliased" => "@locator_aliased_service_alias"})]
class LocatorClient
  getter services : ADI::ServiceLocator(LocatorServiceInterface)

  def initialize(@services : ADI::ServiceLocator(LocatorServiceInterface)); end
end

@[ADI::Register(_services: {"aliased" => "@locator_aliased_service"})]
class InlinedLocatorService
  getter services : ADI::ServiceLocator(LocatorServiceInterface)

  def initialize(@services : ADI::ServiceLocator(LocatorServiceInterface)); end
end

@[ADI::Register(public: true)]
class InlinedLocatorClient
  getter service : InlinedLocatorService

  def initialize(@service : InlinedLocatorService); end
end

describe ADI::ServiceContainer::ResolveValues do
  describe "compiler errors", tags: "compiled" do
    it "errors if a service string reference doesn't map to a known service" do
      assert_compile_time_error "Service 'foo' (Foo) references undefined service 'bar'.", <<-CR
        @[ADI::Register(_id: "@bar")]
        record Foo, id : Int32
      CR
    end

    describe "service locators" do
      it "errors if a service is not keyed by a string" do
        assert_compile_time_error "Service 'foo' (Foo) must key the services of its 'services' service locator by a 'StringLiteral', got 'SymbolLiteral'.", <<-CR
          @[ADI::Register]
          record Bar

          @[ADI::Register(_services: {:bar => "@bar"})]
          record Foo, services : ADI::ServiceLocator(Bar)
        CR
      end

      it "errors if a service is not a service reference" do
        assert_compile_time_error "Service 'foo' (Foo) must provide the services of its 'services' service locator as service references, e.g. '@service_id', got '\"bar\"'.", <<-CR
          @[ADI::Register]
          record Bar

          @[ADI::Register(_services: {"bar" => "bar"})]
          record Foo, services : ADI::ServiceLocator(Bar)
        CR
      end

      it "errors if a service doesn't map to a known service" do
        assert_compile_time_error "Service 'foo' (Foo) references undefined service 'bar'.", <<-CR
          @[ADI::Register(_services: {"bar" => "@bar"})]
          record Foo, services : ADI::ServiceLocator(Int32)
        CR
      end

      it "errors if a service is not compatible with the type of the service locator" do
        assert_compile_time_error "Service 'foo' (Foo) cannot provide the 'bar' service (Bar) via its 'services' service locator, as it is not a 'Baz'.", <<-CR
          @[ADI::Register]
          record Bar

          record Baz

          @[ADI::Register(_services: {"bar" => "@bar"})]
          record Foo, services : ADI::ServiceLocator(Baz)
        CR
      end
    end
  end

  it "resolves the values with the expected priority" do
    ADI.container.value_priority_service
  end

  it "resolves service references with the expected priority" do
    ADI.container.service_value_priority_service
  end

  it "allows passing `false` as an argument" do
    ADI.container.bool_explicit_argument_service.value.should be_false
  end

  describe "service locators" do
    it "only instantiates the services once they are requested" do
      services = ADI.container.locator_client.services

      LocatorLazyService.instantiated?.should be_false
      services.get("lazy").name.should eq "lazy"
      LocatorLazyService.instantiated?.should be_true
      services.get("lazy").should be services.get("lazy")
    end

    it "resolves aliased services" do
      ADI.container.locator_client.services.get("aliased").name.should eq "aliased"
    end

    it "provides the services by their key" do
      ADI.container.locator_client.services.provided_services.should eq ["lazy", "aliased"]
    end

    it "works for inlined services" do
      ADI.container.inlined_locator_client.service.services.get("aliased").name.should eq "aliased"
    end

    it "resolves service locators defined via an extension", tags: "compiled" do
      ASPEC::Methods.assert_compiles <<-'CR', preamble: %(require "../spec_helper.cr")
        module ProvidedInterface; end

        class ProvidedService
          include ProvidedInterface
        end

        class Client
          def initialize(@services : ADI::ServiceLocator(ProvidedInterface)); end
        end

        module MyExtension
          macro included
            macro finished
              {% verbatim do %}
                {%
                  SERVICE_HASH["provided_service"] = {class: ProvidedService}
                  SERVICE_HASH["client"] = {class: Client, public: true, parameters: {services: {value: {"provided" => "@provided_service"}}}}
                %}
              {% end %}
            end
          end
        end

        ADI.add_compiler_pass MyExtension, :before_optimization, 1028

        macro finished
          macro finished
            \{%
              definition = ADI::ServiceContainer::SERVICE_HASH["client"]
              value = definition["parameters"]["services"]["value"]
            %}
            ASPEC.compile_time_assert(\{{ value.stringify == %(ADI::ServiceLocator(ProvidedInterface).new({"provided" => ->{ provided_service.as(ProvidedInterface) }} of String => Proc(ProvidedInterface))) }}, "Expected the service locator to provide the service")
            ASPEC.compile_time_assert(\{{ definition["referenced_services"].includes? "provided_service" }}, "Expected the provided service to be referenced")
            ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["provided_service"] != nil }}, "Expected the provided service to not be removed")
          end
        end
      CR
    end
  end
end
