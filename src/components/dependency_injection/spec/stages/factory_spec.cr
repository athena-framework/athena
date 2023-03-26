require "../spec_helper"

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

describe ADI::ServiceContainer do
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

    it "with the ADI::Inject annotation" do
      ADI::ServiceContainer.new.pseudo_factory.value.should eq 100
    end
  end
end
