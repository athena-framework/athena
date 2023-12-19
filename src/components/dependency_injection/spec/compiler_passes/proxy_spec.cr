require "../spec_helper"

@[ADI::Register]
class ServiceThree
  class_getter? instantiated : Bool = false
  getter value = 123

  def initialize
    @@instantiated = true
  end
end

@[ADI::Register]
class ServiceTwo
  getter value = 123
end

@[ADI::Register]
record Some::Namespace::Service

@[ADI::Register(public: true)]
class ServiceOne
  getter service_two : ADI::Proxy(ServiceTwo)
  getter service_three : ADI::Proxy(ServiceThree)
  getter namespaced_service : ADI::Proxy(Some::Namespace::Service)
  getter service_two_extra : ADI::Proxy(ServiceTwo)

  def initialize(
    @service_two : ADI::Proxy(ServiceTwo),
    @service_three : ADI::Proxy(ServiceThree),
    @namespaced_service : ADI::Proxy(Some::Namespace::Service),
    @service_two_extra : ADI::Proxy(ServiceTwo)
  )
  end

  def test
    1 + 1
  end

  def run
    @service_three.value
  end
end

describe ADI::ServiceContainer do
  describe "with service proxies" do
    it "delays instantiation until the proxy is used" do
      service = ADI.container.service_one
      ServiceThree.instantiated?.should be_false
      service.test
      ServiceThree.instantiated?.should be_false
      service.run.should eq 123
      ServiceThree.instantiated?.should be_true
    end

    it "exposes the service ID and type of the proxied service" do
      service = ADI.container.service_one
      service.service_two_extra.service_id.should eq "service_two"
      service.service_two_extra.service_type.should eq ServiceTwo
      service.service_two_extra.instantiated?.should be_false
      service.service_two_extra.value.should eq 123
      service.service_two_extra.instantiated?.should be_true

      service.namespaced_service.service_id.should eq "some_namespace_service"
      service.namespaced_service.service_type.should eq Some::Namespace::Service
    end
  end
end
