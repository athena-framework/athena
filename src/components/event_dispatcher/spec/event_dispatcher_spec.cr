require "./spec_helper"

class PreFoo < AED::Event; end

class PostFoo < AED::Event; end

class PreBar < AED::Event; end

class TestListener
  include AED::EventListenerInterface

  getter values = [] of Int32

  @[AEDA::AsEventListener]
  def on_pre1(event : PreFoo) : Nil
    @values << 1
  end

  @[AEDA::AsEventListener(priority: 10)]
  def on_pre2(event : PreFoo, dispatcher : AED::EventDispatcherInterface) : Nil
    @values << 2
  end
end

struct EventDispatcherTest < ASPEC::TestCase
  @dispatcher : AED::EventDispatcher

  def initialize
    @dispatcher = AED::EventDispatcher.new
  end

  def test_initial_state : Nil
    @dispatcher.listeners.should be_empty
    @dispatcher.has_listeners?(PreFoo).should be_false
    @dispatcher.has_listeners?(PostFoo).should be_false
  end

  def test_listener : Nil
    @dispatcher.listener PreFoo do
    end

    @dispatcher.listener PostFoo do
    end

    @dispatcher.has_listeners?.should be_true
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.has_listeners?(PreBar).should be_false

    @dispatcher.listeners(PreFoo).size.should eq 1
    @dispatcher.listeners(PostFoo).size.should eq 1
    @dispatcher.listeners.size.should eq 2
  end

  def test_listeners_sorted_by_priority : Nil
    vals = [] of Int32

    callback1 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { vals << 1 }
    callback2 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { vals << 2 }
    callback3 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { vals << 3 }
    callback4 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { vals << 4 }

    @dispatcher.listener PreFoo, priority: -10, &callback1
    @dispatcher.listener PreFoo, priority: 10, &callback2
    @dispatcher.listener PreFoo, &callback3
    @dispatcher.listener PreFoo, priority: 20, &callback4

    # `#dispatch` inherently calls `#listeners`
    @dispatcher.dispatch PreFoo.new

    @dispatcher.listeners(PreFoo).size.should eq 4

    vals.should eq [4, 2, 3, 1]
  end

  def test_all_listeners_sorts_by_priority
    pre_foo_vals = [] of Int32
    post_foo_vals = [] of Int32

    callback1 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { pre_foo_vals << 1 }
    callback2 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { pre_foo_vals << 2 }
    callback3 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { pre_foo_vals << 3 }

    callback4 = Proc(PostFoo, AED::EventDispatcherInterface, Nil).new { post_foo_vals << 4 }
    callback5 = Proc(PostFoo, AED::EventDispatcherInterface, Nil).new { post_foo_vals << 5 }
    callback6 = Proc(PostFoo, AED::EventDispatcherInterface, Nil).new { post_foo_vals << 6 }

    @dispatcher.listener PreFoo, priority: -10, &callback1
    @dispatcher.listener PreFoo, &callback2
    @dispatcher.listener PreFoo, priority: 10, &callback3

    @dispatcher.listener PostFoo, priority: -10, &callback4
    @dispatcher.listener PostFoo, &callback5
    @dispatcher.listener PostFoo, priority: 10, &callback6

    listeners = @dispatcher.listeners
    listeners.keys.should eq [PreFoo, PostFoo]
    listeners[PreFoo].size.should eq 3
    listeners[PostFoo].size.should eq 3

    # `#dispatch` inherently calls `#listeners`
    @dispatcher.dispatch PreFoo.new
    @dispatcher.dispatch PostFoo.new

    pre_foo_vals.should eq [3, 2, 1]
    post_foo_vals.should eq [6, 5, 4]
  end

  def test_listener_priority : Nil
    callback1 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { }
    callback2 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { }

    @dispatcher.listener PreFoo, priority: -10, &callback1
    @dispatcher.listener PreFoo, &callback2

    @dispatcher.listener_priority(PreFoo, callback1).should eq -10
    @dispatcher.listener_priority(PreFoo, callback2).should eq 0
    @dispatcher.listener_priority(PreBar, callback1).should be_nil
    @dispatcher.listener_priority(PreFoo, Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { }).should be_nil
  end

  def test_dispatch_stop_event_propagation : Nil
    pre_foo_invoked = false
    other_pre_foo_invoked = false

    @dispatcher.listener PreFoo do |event|
      pre_foo_invoked = true
      event.stop_propagation
    end

    @dispatcher.listener PreFoo do |event|
      other_pre_foo_invoked = true
    end

    @dispatcher.dispatch PreFoo.new

    pre_foo_invoked.should be_true
    other_pre_foo_invoked.should be_false
  end

  def test_remove_listener : Nil
    callback1 = Proc(PreFoo, AED::EventDispatcherInterface, Nil).new { }

    @dispatcher.listener PreFoo, &callback1
    @dispatcher.has_listeners?(PreFoo).should be_true

    @dispatcher.remove_listener PreFoo, callback1
    @dispatcher.has_listeners?(PreFoo).should be_false

    @dispatcher.remove_listener PostFoo, callback1
  end

  def test_add_event_listener_instance
    listener = TestListener.new

    @dispatcher.listener listener

    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 2

    @dispatcher.dispatch PreFoo.new

    listener.values.should eq [2, 1]
  end

  def test_remove_event_listener_instance
    listener = TestListener.new

    @dispatcher.listener listener
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 2

    @dispatcher.remove_listener listener

    @dispatcher.has_listeners?(PreFoo).should be_false
    @dispatcher.listeners(PreFoo).should be_empty
  end
end
