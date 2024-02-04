require "./spec_helper"

@[ADI::Register(public: true)]
class ValueStore
  property value : Int32 = 1
end

describe Athena::DependencyInjection do
  describe ".container" do
    it "returns a container" do
      ADI.container.should be_a ADI::ServiceContainer
    end

    it "returns a fiber specific container" do
      channel = Channel(Int32).new

      container = ADI.container

      spawn do
        inner_container = ADI.container
        inner_container.value_store.value = 2
        channel.send inner_container.value_store.value
      end

      channel.receive.should_not eq container.value_store.value
    end
  end
end
