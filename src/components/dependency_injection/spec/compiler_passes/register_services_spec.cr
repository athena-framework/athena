require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

# Happy Path
@[ADI::Register]
class SingleService
  getter value : Int32 = 1
end

@[ADI::Register(public: true)]
class SingleClient
  getter service : SingleService

  def initialize(@service : SingleService); end
end

# Factories
class TestFactory
  def self.create_factory_tuple(value : Int32) : FactoryTuple
    FactoryTuple.new value * 3
  end

  def self.create_factory_service(value_provider : ValueProvider) : FactoryService
    FactoryService.new value_provider.valuee
  end
end

@[ADI::Register(_value: 10, public: true, factory: {TestFactory, "create_factory_tuple"})]
class FactoryTuple
  getter value : Int32

  def initialize(@value : Int32); end
end

@[ADI::Register(_value: 10, public: true, factory: "double")]
class FactoryString
  getter value : Int32

  def self.double(value : Int32) : self
    new value * 2
  end

  def initialize(@value : Int32); end
end

@[ADI::Register(_value: 50, public: true)]
class PseudoFactory
  getter value : Int32

  @[ADI::Inject]
  def self.new_instance(value : Int32) : self
    new value * 2
  end

  def initialize(@value : Int32); end
end

@[ADI::Register]
record ValueProvider, valuee : Int32 = 10

@[ADI::Register(public: true, factory: {TestFactory, "create_factory_service"})]
class FactoryService
  getter value : Int32

  def initialize(@value : Int32); end
end

@[ADI::Register(_value: 99, public: true)]
class InstanceInjectService
  getter value : Int32

  def initialize(value : String)
    @value = value.to_i
  end

  @[ADI::Inject]
  def initialize(@value : Int32); end
end

# Calls
@[ADI::Register(public: true, calls: [
  {"foo"},
  {"foo", {3}},
  {"foo", {6}},
])]
class CallClient
  getter values = [] of Int32

  def foo(value : Int32 = 1)
    @values << value
  end
end

describe ADI::ServiceContainer::RegisterServices do
  describe "compiler errors", tags: "compiled" do
    it "errors if a service has multiple ADI::Register annotations but not all of them have a name" do
      assert_error "Failed to auto register services for 'Foo'. Each service must explicitly provide a name when auto registering more than one service based on the same type.", <<-CR
        @[ADI::Register(name: "one")]
        @[ADI::Register]
        record Foo
      CR
    end

    it "errors if the generic service does not have a name." do
      assert_error "Failed to auto register service for 'Foo(T)'. Generic services must explicitly provide a name.", <<-CR
        @[ADI::Register]
        record Foo(T)
      CR
    end

    it "errors if the service is already registered" do
      assert_error "Failed to auto register service for 'my_service' (MyService). It is already registered.", <<-CR
        @[ADI::Register]
        record MyService

        module MyExtension
          macro included
            macro finished
              {% verbatim do %}
                {%
                  SERVICE_HASH["my_service"] = {
                    class:      MyService,
                  }
                %}
              {% end %}
            end
          end
        end

        ADI.add_compiler_pass MyExtension, :before_optimization, 1028
        CR
    end

    describe "factory" do
      it "errors if method is an instance method" do
        assert_error "Failed to auto register service 'foo'. Factory method 'foo' within 'Foo' is an instance method.", <<-CR
        @[ADI::Register(factory: "foo")]
        record Foo do
          def foo; end
        end
      CR
      end

      it "errors if the method is missing" do
        assert_error "Failed to auto register service 'foo'. Factory method 'foo' within 'Foo' does not exist.", <<-CR
        @[ADI::Register(factory: "foo")]
        record Foo
      CR
      end
    end

    describe "tags" do
      it "errors if not all tags have a `name` field" do
        assert_error "Failed to auto register service 'foo'. All tags must have a name.", <<-CR
          @[ADI::Register(tags: [{priority: 100}])]
          record Foo
        CR
      end

      it "errors if not all tags are of the proper type" do
        assert_error "Tag '100' must be a 'StringLiteral' or 'NamedTupleLiteral', got 'NumberLiteral'.", <<-CR
          @[ADI::Register(tags: [100])]
          record Foo
        CR
      end
    end

    describe "calls" do
      it "errors if the method of a call is empty" do
        assert_error "Method name cannot be empty.", <<-CR
        @[ADI::Register(calls: [{""}])]
        record Foo
      CR
      end

      it "errors if the method does not exist on the type" do
        assert_error "Failed to auto register service for 'foo' (Foo). Call references non-existent method 'foo'.", <<-CR
        @[ADI::Register(calls: [{"foo"}])]
        record Foo
      CR
      end
    end
  end

  describe "with factory based services" do
    it "supports passing a tuple" do
      ADI::ServiceContainer.new.factory_tuple.value.should eq 30
    end

    it "supports passing the string method name" do
      ADI::ServiceContainer.new.factory_string.value.should eq 20
    end

    it "supports auto resolving factory method service dependencies" do
      ADI::ServiceContainer.new.factory_service.value.should eq 10
    end

    describe "with an ADI:Inject annotation" do
      it "on a class method" do
        ADI::ServiceContainer.new.pseudo_factory.value.should eq 100
      end

      it "allows specifying which initialize method to use" do
        ADI::ServiceContainer.new.instance_inject_service.value.should eq 99
      end
    end
  end

  it "correctly resolves the service" do
    service = ADI.container.single_client.service
    service.should be_a SingleService
    service.value.should eq 1
  end

  it "registers calls" do
    ADI.container.call_client.values.should eq [1, 3, 6]
  end
end
