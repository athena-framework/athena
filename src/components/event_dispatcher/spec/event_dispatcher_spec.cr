require "./spec_helper"

class TestEvent < AED::Event
  property value : Int32 = 0

  property? should_stop_propagation : Bool = false
end

class FakeEvent < AED::Event
end

class NoListenerEvent < AED::Event
end

struct OtherTestListener
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      TestEvent => 12,
    }
  end

  def call(event : TestEvent, dispatcher : AED::EventDispatcherInterface) : Nil
    event.stop_propagation if event.should_stop_propagation?

    event.value += 1
  end
end

struct TestListener
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      TestEvent => 0,
      FakeEvent => 4,
    }
  end

  def call(event : TestEvent, dispatcher : AED::EventDispatcherInterface) : Nil
    event.value += 2
  end

  def call(event : FakeEvent, dispatcher : AED::EventDispatcherInterface) : Nil
  end
end

describe AED::EventDispatcher do
  describe "#add_listener" do
    describe Proc do
      it "should add the provided proc as a listener" do
        dispatcher = AED::EventDispatcher.new [] of AED::EventListenerInterface

        dispatcher.has_listeners?(FakeEvent).should be_false

        listener = AED.create_listener(FakeEvent) { }

        dispatcher.add_listener FakeEvent, listener

        dispatcher.has_listeners?(FakeEvent).should be_true
      end
    end

    describe AED::EventListenerInterface do
      it "should add the provided listener" do
        dispatcher = AED::EventDispatcher.new [] of AED::EventListenerInterface

        dispatcher.has_listeners?(TestEvent).should be_false

        listener = TestListener.new

        dispatcher.add_listener TestEvent, listener

        dispatcher.has_listeners?(TestEvent).should be_true
      end
    end
  end

  describe "#dispatch" do
    it "should pass the event to all listeners" do
      event = TestEvent.new

      AED::EventDispatcher.new.dispatch event

      event.value.should eq 3
    end

    it "should stop calling listeners if the event propagation is stopped" do
      event = TestEvent.new
      event.should_stop_propagation = true

      AED::EventDispatcher.new.dispatch event

      event.value.should eq 1
    end
  end

  describe "#listeners" do
    describe :event do
      describe "that has listeners" do
        it "should return an array of Listeners" do
          dispatcher = AED::EventDispatcher.new

          listeners = dispatcher.listeners(TestEvent)

          event = TestEvent.new

          listeners.size.should eq 2
          listeners.first.call(event, dispatcher)

          event.value.should eq 1
        end
      end

      describe "that doesn't have any listeners" do
        it "should return an empty array" do
          AED::EventDispatcher.new.listeners(NoListenerEvent).should be_empty
        end
      end

      describe "when a new listener is added" do
        describe Proc do
          it "should resort the listeners" do
            dispatcher = AED::EventDispatcher.new

            listener = AED.create_listener(TestEvent) { event.value = 14 }

            dispatcher.add_listener TestEvent, listener, 99

            listeners = dispatcher.listeners(TestEvent)

            event = TestEvent.new

            listeners.size.should eq 3
            listeners.first.call(event, dispatcher)

            event.value.should eq 14
          end
        end

        describe AED::EventListenerInterface do
          it "should resort the listeners" do
            dispatcher = AED::EventDispatcher.new

            listener = TestListener.new

            dispatcher.add_listener TestEvent, listener, 99

            listeners = dispatcher.listeners(TestEvent)

            event = TestEvent.new

            listeners.size.should eq 3
            listeners.first.call(event, dispatcher)

            event.value.should eq 2
          end
        end
      end
    end

    describe :no_event do
      it "should return an array of listeners" do
        AED::EventDispatcher.new.listeners.size.should eq 3
      end

      describe "when a new listener is added" do
        describe Proc do
          it "should resort the listeners" do
            dispatcher = AED::EventDispatcher.new

            listener = AED.create_listener(TestEvent) { event.value = 14 }

            dispatcher.add_listener TestEvent, listener, 99

            listeners = dispatcher.listeners

            event = TestEvent.new

            listeners.size.should eq 4
            listeners.first.call(event, dispatcher)

            event.value.should eq 14
          end
        end
      end
    end
  end

  describe "#has_listeners?" do
    describe :event do
      describe "and there are some listening" do
        it "should return true" do
          AED::EventDispatcher.new.has_listeners?(TestEvent).should be_true
        end
      end

      describe "and there are none listening" do
        it "should return false" do
          AED::EventDispatcher.new.has_listeners?(NoListenerEvent).should be_false
        end
      end
    end

    describe :no_event do
      describe "and there are some listening" do
        it "should return true" do
          AED::EventDispatcher.new.has_listeners?.should be_true
        end
      end

      describe "and there are some listening" do
        it "should return false" do
          AED::EventDispatcher.new([] of AED::EventListenerInterface).has_listeners?.should be_false
        end
      end
    end
  end

  describe "#listener_priority" do
    describe "that exists" do
      it "should return the listener priority of the event" do
        AED::EventDispatcher.new.listener_priority(FakeEvent, TestListener).should eq 4
      end
    end

    describe "that doesn't have any listeners" do
      it "should return nil" do
        AED::EventDispatcher.new.listener_priority(NoListenerEvent, TestListener).should be_nil
      end
    end

    describe "where a listener isn't listening on that event" do
      it "should return nil" do
        AED::EventDispatcher.new.listener_priority(FakeEvent, OtherTestListener).should be_nil
      end
    end
  end

  describe "#remove_listener" do
    describe AED::EventListenerInterface.class do
      it "should remove the listeners of the given type off the event" do
        dispatcher = AED::EventDispatcher.new [TestListener.new]

        dispatcher.has_listeners?(TestEvent).should be_true

        dispatcher.remove_listener TestEvent, TestListener

        dispatcher.has_listeners?(TestEvent).should be_false
      end
    end

    describe Proc do
      it "should remove the listeners procs off the given event" do
        listener = AED.create_listener(FakeEvent) { }

        dispatcher = AED::EventDispatcher.new [] of AED::EventListenerInterface

        dispatcher.add_listener FakeEvent, listener

        dispatcher.has_listeners?(FakeEvent).should be_true

        dispatcher.remove_listener FakeEvent, listener

        dispatcher.has_listeners?(FakeEvent).should be_false
      end
    end

    describe AED::EventListenerInterface do
      it "should remove the listeners based on a listener instance" do
        listener = TestListener.new

        dispatcher = AED::EventDispatcher.new [listener]

        dispatcher.has_listeners?(TestEvent).should be_true

        dispatcher.remove_listener TestEvent, listener

        dispatcher.has_listeners?(TestEvent).should be_false
      end
    end
  end
end
