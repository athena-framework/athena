require "../spec_helper"

@[ADI::Register]
class SingleService
  getter value : Int32 = 1
end

@[ADI::Register(public: true)]
class SingleClient
  getter service : SingleService

  def initialize(@service : SingleService); end
end

describe ADI::ServiceContainer do
  it "correctly resolves the service" do
    service = ADI.container.single_client.service
    service.should be_a SingleService
    service.value.should eq 1
  end
end
