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

module SameInstanceAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias]
class SameInstancePrimary
  include SameInstanceAliasInterface
end

@[ADI::Register(public: true)]
record SameInstanceClient, a : SameInstancePrimary, b : SameInstanceAliasInterface

describe ADI::ServiceContainer do
  it "resolves the service with a matching constructor name" do
    ADI.container.auto_wire_service.auto_wire_two.should be_a AutoWireTwo
  end

  it "resolves aliases to the same underlying instance" do
    service = ADI.container.same_instance_client
    service.a.should be service.b
  end
end
