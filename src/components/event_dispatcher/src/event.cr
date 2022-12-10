require "./stoppable_event"

# Base class for all event objects.
# This event does not contain any event data.
# Custom events should inherit from this type, and include any useful information that listeners may need.
# The `AED::GenericEvent` type may be used for simple use cases, but dedicated event types are still considered a best practice.
#
# ```
# # Define a custom event
# class ExceptionEvent < AED::Event
#   getter exception : Exception
#
#   def initialize(@exception : Exception); end
# end
#
# # Dispatch a custom event
# exception = ArgumentError.new "Value cannot be negative"
# dispatcher.dispatch ExceptionEvent.new exception
# ```
#
# Abstract event classes may also be used to share common data/methods between a group of related events.
# However they cannot be used as a catchall to listen on all events that extend it.
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

  def self.callable(*, priority : Int32 = 0, &block : self, AED::EventDispatcherInterface -> Nil) : AED::Callable
    AED::Callable::EventDispatcher(self).new block, priority
  end
end
