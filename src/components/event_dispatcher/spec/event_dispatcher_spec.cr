require "./spec_helper"

class PreFoo < AED::Event; end

class PostFoo < AED::Event; end

class PreBar < AED::Event; end

class ContractEvent < ACTR::EventDispatcher::Event; end

class Sum < AED::Event
  property value : Int32 = 0
end

class TestListener
  getter values = [] of Int32

  @[AEDA::AsEventListener]
  def on_pre1(event : PreFoo) : Nil
    @values << 1
  end

  @[AEDA::AsEventListener(priority: 10)]
  def on_pre2(event : PreFoo, dispatcher : AED::EventDispatcherInterface) : Nil
    @values << 2
  end

  @[AEDA::AsEventListener]
  def on_post1(event : PostFoo) : Nil
    @values << 3
  end

  @[AEDA::AsEventListener]
  def on_contract(event : ContractEvent) : Nil
    @values << -1
  end
end

module SomeInterface; end

abstract class Animal; end

class Dog < Animal; end

class Cat < Animal
  include SomeInterface
end

abstract class ParentAnimal < Animal; end

class Sloth < ParentAnimal
  include SomeInterface
end

class ThreeToedSloth < Sloth; end

class GenericAnimalEvent(T) < AED::Event
  getter animal : T

  def initialize(@animal : T); end
end

class AnimalListener
  getter all_animal_calls : Array(Animal.class) = [] of Animal.class
  getter only_child_animal_calls : Array(Animal.class) = [] of Animal.class
  getter only_interface_animal_calls : Array(Animal.class) = [] of Animal.class
  getter non_abstract_animal_calls : Array(Animal.class) = [] of Animal.class

  @[AEDA::AsEventListener]
  def all_animals(event : GenericAnimalEvent(Animal)) : Nil
    @all_animal_calls << event.animal.class
  end

  @[AEDA::AsEventListener]
  def only_child_animals(event : GenericAnimalEvent(ParentAnimal), dispatcher : AED::EventDispatcherInterface) : Nil
    @only_child_animal_calls << event.animal.class
  end

  @[AEDA::AsEventListener]
  def only_interface_animals(event : GenericAnimalEvent(SomeInterface)) : Nil
    @only_interface_animal_calls << event.animal.class
  end

  @[AEDA::AsEventListener]
  def non_abstract_animals(event : GenericAnimalEvent(Sloth)) : Nil
    @non_abstract_animal_calls << event.animal.class
  end
end

struct EventDispatcherTest < ASPEC::TestCase
  @dispatcher : AED::EventDispatcher

  def initialize
    @dispatcher = AED::EventDispatcher.new
  end

  @[Tags("compiled")]
  def test_listener_not_passed_event_class : Nil
    ASPEC::Methods.assert_compile_time_error "expected argument #1 to 'listener' to be Athena::Contracts::EventDispatcher::Event.class, not String.", <<-CR
      require "./spec_helper.cr"

      AED::EventDispatcher.new.listener String do
      end
    CR
  end

  def test_initial_state : Nil
    @dispatcher.listeners.should be_empty
    @dispatcher.has_listeners?.should be_false
    @dispatcher.has_listeners?(PreFoo).should be_false
    @dispatcher.has_listeners?(PostFoo).should be_false
  end

  def test_listener_block : Nil
    @dispatcher.listener PreFoo do
    end

    @dispatcher.listener PreFoo, name: "#2" do
    end

    @dispatcher.listener PostFoo do
    end

    @dispatcher.has_listeners?.should be_true
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.has_listeners?(PreBar).should be_false

    @dispatcher.listeners(PreFoo).size.should eq 2
    @dispatcher.listeners(PreFoo).map(&.name).should eq ["unknown callable", "#2"]
    @dispatcher.listeners(PostFoo).size.should eq 1
    @dispatcher.listeners.size.should eq 2
  end

  def test_listener_callable : Nil
    callback1 = PreFoo.callable do
    end

    callback2 = PostFoo.callable do
    end

    @dispatcher.listener callback1
    @dispatcher.listener callback2

    @dispatcher.has_listeners?.should be_true
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.has_listeners?(PreBar).should be_false

    @dispatcher.listeners(PreFoo).size.should eq 1
    @dispatcher.listeners(PostFoo).size.should eq 1
    @dispatcher.listeners.size.should eq 2
  end

  def test_listeners_sorted_by_priority : Nil
    callback1 = PreFoo.callable(priority: -10) { }
    callback2 = PreFoo.callable(priority: 10) { }
    callback3 = PreFoo.callable { }
    callback4 = PreFoo.callable(priority: 20) { }
    callback5 = PreFoo.callable { }

    @dispatcher.listener callback1
    @dispatcher.listener callback2
    @dispatcher.listener callback3
    @dispatcher.listener callback4

    # Returns a new copy with thew new priority set
    callback5 = @dispatcher.listener callback5, priority: 5

    @dispatcher.listeners(PreFoo).should eq([
      callback4,
      callback2,
      callback5,
      callback3,
      callback1,
    ])
  end

  def test_all_listeners_sorts_by_priority
    callback1 = PreFoo.callable(priority: -10) { }
    callback2 = PreFoo.callable { }
    callback3 = PreFoo.callable(priority: 10) { }

    callback4 = PostFoo.callable(priority: -10) { }
    callback5 = PostFoo.callable { }
    callback6 = PostFoo.callable(priority: 10) { }

    @dispatcher.listener callback1
    @dispatcher.listener callback2
    @dispatcher.listener callback3
    @dispatcher.listener callback4
    @dispatcher.listener callback5
    @dispatcher.listener callback6

    @dispatcher.listeners.should eq({
      PreFoo  => [callback3, callback2, callback1],
      PostFoo => [callback6, callback5, callback4],
    })
  end

  def test_listeners_are_sorted_stably : Nil
    callback1 = PreFoo.callable(priority: -10) { }
    callback2 = PreFoo.callable { }
    callback3 = PreFoo.callable { }
    callback4 = PreFoo.callable(priority: 10) { }

    @dispatcher.listener callback1
    @dispatcher.listener callback2
    @dispatcher.listener callback3
    @dispatcher.listener callback4

    @dispatcher.listeners(PreFoo).should eq([
      callback4,
      callback2,
      callback3,
      callback1,
    ])
  end

  def test_callable_exposes_correct_priority : Nil
    callback1 = PreFoo.callable priority: -10 { }
    callback2 = PreFoo.callable { }
    callback3 = PreFoo.callable priority: 50 { }

    @dispatcher.listener callback1
    @dispatcher.listener callback2

    # Returns a new copy with thew new priority set
    callback3 = @dispatcher.listener callback3, priority: 10

    callback1.priority.should eq -10
    callback2.priority.should eq 0
    callback3.priority.should eq 10
    PreFoo.callable { }.priority.should eq 0
  end

  def test_dispatch : Nil
    event = Sum.new

    @dispatcher.listener Sum do |e|
      e.value += 10
    end

    @dispatcher.listener PostFoo do
    end

    @dispatcher.dispatch event
    @dispatcher.dispatch PostFoo.new

    event.value.should eq 10
  end

  def test_dispatch_contract_event : Nil
    event = ContractEvent.new

    @dispatcher.listener ContractEvent do
    end

    returned_event = @dispatcher.dispatch event
    returned_event.should be event
  end

  def test_dispatch_sub_dispatch : Nil
    value = 0

    @dispatcher.listener Sum do
      value += 123
    end

    @dispatcher.listener PostFoo do |_, dispatcher|
      dispatcher.dispatch Sum.new
    end

    @dispatcher.dispatch PostFoo.new

    value.should eq 123
  end

  def test_dispatch_stop_event_propagation : Nil
    pre_foo_invoked = false
    other_pre_foo_invoked = false

    @dispatcher.listener PreFoo do |event|
      pre_foo_invoked = true
      event.stop_propagation
    end

    @dispatcher.listener PreFoo do
      other_pre_foo_invoked = true
    end

    @dispatcher.dispatch PreFoo.new

    pre_foo_invoked.should be_true
    other_pre_foo_invoked.should be_false
  end

  def test_listener_generic_polymorphism : Nil
    animal_listener = AnimalListener.new

    @dispatcher.listener animal_listener

    @dispatcher.has_listeners?(GenericAnimalEvent(Cat)).should be_true
    @dispatcher.has_listeners?(GenericAnimalEvent(Sloth)).should be_true
    @dispatcher.has_listeners?(GenericAnimalEvent(ThreeToedSloth)).should be_true
    @dispatcher.has_listeners?(GenericAnimalEvent(Dog)).should be_true

    # Should not include module/abstract types that cannot actually exist.
    @dispatcher.has_listeners?(GenericAnimalEvent(Animal)).should be_false
    @dispatcher.has_listeners?(GenericAnimalEvent(SomeInterface)).should be_false
    @dispatcher.has_listeners?(GenericAnimalEvent(ParentAnimal)).should be_false

    @dispatcher.dispatch GenericAnimalEvent(Cat).new Cat.new
    @dispatcher.dispatch GenericAnimalEvent(Sloth).new Sloth.new
    @dispatcher.dispatch GenericAnimalEvent(Dog).new Dog.new
    @dispatcher.dispatch GenericAnimalEvent(ThreeToedSloth).new ThreeToedSloth.new

    animal_listener.all_animal_calls.should eq [Cat, Sloth, Dog, ThreeToedSloth]
    animal_listener.only_child_animal_calls.should eq [Sloth, ThreeToedSloth]
    animal_listener.only_interface_animal_calls.should eq [Cat, Sloth]
    animal_listener.non_abstract_animal_calls.should eq [Sloth, ThreeToedSloth]
  end

  def test_remove_listener : Nil
    callback1 = PreFoo.callable { }

    @dispatcher.listener callback1
    @dispatcher.has_listeners?(PreFoo).should be_true

    @dispatcher.remove_listener callback1
    @dispatcher.has_listeners?(PreFoo).should be_false

    @dispatcher.remove_listener callback1
  end

  def test_remove_listener_via_get : Nil
    @dispatcher.listener(PreFoo) { }

    @dispatcher.has_listeners?(PreFoo).should be_true

    @dispatcher.remove_listener @dispatcher.listeners(PreFoo).first

    @dispatcher.has_listeners?(PreFoo).should be_false
  end

  def test_add_event_listener_instance
    listener = TestListener.new

    @dispatcher.listener listener

    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 2
    @dispatcher.listeners(PreFoo).map(&.name).should eq ["TestListener#on_pre2", "TestListener#on_pre1"]

    @dispatcher.dispatch PreFoo.new

    listener.values.should eq [2, 1]
  end

  def test_remove_event_listener_instance
    listener = TestListener.new
    listener2 = TestListener.new

    @dispatcher.listener listener
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 2

    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.listeners(PostFoo).size.should eq 1

    @dispatcher.listener listener2
    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 4

    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.listeners(PostFoo).size.should eq 2

    @dispatcher.remove_listener listener

    @dispatcher.has_listeners?(PreFoo).should be_true
    @dispatcher.listeners(PreFoo).size.should eq 2

    @dispatcher.has_listeners?(PostFoo).should be_true
    @dispatcher.listeners(PostFoo).size.should eq 1

    @dispatcher.remove_listener listener2

    @dispatcher.has_listeners?(PreFoo).should be_false
    @dispatcher.has_listeners?(PostFoo).should be_false
    @dispatcher.listeners.should be_empty
  end

  def test_remove_event_listener_instance_diff_instance
    listener = TestListener.new
    listener2 = TestListener.new

    @dispatcher.listener listener
    @dispatcher.listener listener2

    @dispatcher.listeners(PreFoo).size.should eq 4

    @dispatcher.remove_listener TestListener.new

    @dispatcher.listeners(PreFoo).size.should eq 4

    @dispatcher.remove_listener listener2

    @dispatcher.listeners(PreFoo).size.should eq 2
  end
end
