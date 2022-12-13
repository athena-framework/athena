require "./spec_helper"

private class TestListener
  include AED::EventListenerInterface
end

describe AED::Callable do
  describe "#name" do
    it "defaults to a generic name if not supplied" do
      callable = AED::Callable::Event(AED::GenericEvent(String, String)).new(
        Proc(AED::GenericEvent(String, String), Nil).new { },
        0,
        nil,
      )

      callable.name.should eq "unknown callable"
    end

    it "EventListenerInstance defaults to a more useful name" do
      callable = AED::Callable::EventListenerInstance(TestListener, AED::GenericEvent(String, String)).new(
        Proc(AED::GenericEvent(String, String), Nil).new { },
        TestListener.new,
        0,
        nil,
      )

      callable.name.should eq "unknown TestListener method"
    end
  end
end
