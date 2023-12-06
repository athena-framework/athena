require "../spec_helper"

module AutoWireInterface; end

@[ADI::Register]
record AutoWireOne do
  include AutoWireInterface
end

@[ADI::Register]
record AutoWireTwo do
  include AutoWireInterface
end

@[ADI::Register(public: true)]
record AutoWireService, auto_wire_two : AutoWireInterface

describe ADI::ServiceContainer do
  it "resolves the service with a matching constructor name" do
    ADI.container.auto_wire_service.auto_wire_two.should be_a AutoWireTwo
  end
end
