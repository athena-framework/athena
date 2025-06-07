# Extension of [ACTR::EventDispatcher::Event](/Contracts/EventDispatcher/Event/) to add additional functionality.
#
# ## Generics
#
# Events with generic type variables are also supported, the `AED::GenericEvent` event is an example of this.
# Listeners on events with generics are a bit unique in how they behave in that each unique instantiation is treated as its own event.
# For example:
#
# ```
# class Foo; end
#
# subject = Foo.new
#
# dispatcher.listener AED::GenericEvent(Foo, Int32) do |e|
#   e["counter"] += 1
# end
#
# dispatcher.listener AED::GenericEvent(String, String) do |e|
#   e["class"] = e.subject.upcase
# end
#
# dispatcher.dispatch AED::GenericEvent.new subject, data = {"counter" => 0}
#
# data["counter"] # => 1
#
# dispatcher.dispatch AED::GenericEvent.new "foo", data = {"bar" => "baz"}
#
# data["class"] # => "FOO"
# ```
#
# Notice that the listeners are registered with the generic types included.
# This allows the component to treat `AED::GenericEvent(String, Int32)` differently than `AED::GenericEvent(String, String)`.
# The added benefit of this is that the listener is also aware of the type returned by the related methods, so no manual casting is required.
#
# TIP: Use type aliases to give better names to commonly used generic types.
# ```
# alias UserCreatedEvent = AED::GenericEvent(User, String)
# ```
abstract class Athena::EventDispatcher::Event < Athena::Contracts::EventDispatcher::Event
  # Returns an `AED::Callable` based on the event class the method was called on.
  # Optionally allows customizing the *priority* and *name* of the listener.
  #
  # ```
  # class MyEvent < AED::Event; end
  #
  # callable = MyEvent.callable do |event, dispatcher|
  #   # Do something with the event, and/or dispatcher
  # end
  #
  # dispatcher.listener callable
  # ```
  #
  # Essentially the same as using [AED::EventDispatcherInterface#listener(event_class,*,priority,&)][Athena::EventDispatcher::EventDispatcherInterface#listener(callable,*,priority)], but removes the need to pass the *event_class*.
  def self.callable(*, priority : Int32 = 0, name : String? = nil, &block : self, AED::EventDispatcherInterface -> Nil) : AED::Callable
    AED::Callable::EventDispatcher(self).new block, priority, name
  end
end
