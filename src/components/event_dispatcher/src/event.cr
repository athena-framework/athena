require "./stoppable_event"

# An event consists of a subclass of this type, usually with extra context specific information.
# The metaclass of the event type is used as a unique identifier, which generally should end in a verb that indicates what action has been taken.
# The `AED::GenericEvent` type may be used for simple use cases, but dedicated event types are still considered a best practice.
#
# ```
# # Define a custom event
# class ExceptionRaisedEvent < AED::Event
#   getter exception : Exception
#
#   def initialize(@exception : Exception); end
# end
#
# # Dispatch a custom event
# exception = ArgumentError.new "Value cannot be negative"
# dispatcher.dispatch ExceptionRaisedEvent.new exception
# ```
#
# Abstract event classes may also be used to share common data/methods between a group of related events.
# However they cannot be used as a catchall to listen on all events that extend it.
#
# ## Stopping Propagation
#
# In some cases it may make sense for a listener to prevent any other listeners from being called for a specific event.
# In order to do this, the listener needs a way to tell the dispatcher that it should stop propagation, i.e. do not notify any more listeners.
# The base event type includes `AED::StoppableEvent` that enables this behavior.
# Checkout the related module for more information.
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
abstract class Athena::EventDispatcher::Event
  include Athena::EventDispatcher::StoppableEvent

  # Returns an `AED::Callable` based on the event class the method was called on.
  # Optionally allows customizing the *priority* of the listener.
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
  def self.callable(*, priority : Int32 = 0, &block : self, AED::EventDispatcherInterface -> Nil) : AED::Callable
    AED::Callable::EventDispatcher(self).new block, priority
  end
end
