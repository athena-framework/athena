require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

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

describe ADI::ServiceContainer::RegisterServices do
  describe "compiler errors", tags: "compiled" do
    it "errors if a factory method is an instance method" do
      assert_error "Failed to register service 'foo'. Factory method 'foo' within 'Foo' is an instance method.", <<-CR
        @[ADI::Register(factory: "foo")]
        record Foo do
          def foo; end
        end
      CR
    end

    it "errors if a factory method is missing" do
      assert_error "Failed to register service 'foo'. Factory method 'foo' within 'Foo' does not exist.", <<-CR
        @[ADI::Register(factory: "foo")]
        record Foo
      CR
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
end
