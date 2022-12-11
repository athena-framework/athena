# An event dispatcher is the primary type of `Athena::EventDispatcher`.
# It maintains a registry of listeners, with events also being dispatched via this type.
# When dispatched, the dispatcher notifies all listeners registered with that event.
#
# ## Usage
#
# Listeners can be added in a few ways, with the simplest being registering a block directly on the dispatcher instance.
#
# ```
# class MyEvent < AED::Event; end
#
# dispatcher.listener MyEvent do |event, dispatcher|
#   # Do something with the event, and/or dispatcher
# end
# ```
#
# Another way involves passing an `AED::Callable` instance, created manually or via the `AED::Event.callable` method.
# Lastly, an `AED::EventListenerInterface` instance may also be passed.
#
# Once all listeners are registered, you can begin to dispatch events.
# Dispatching an event is simply calling the `#dispatch` method with an `AED::Event` subclass instance as an argument.
#
# ### Listener Priority
#
# As you may have noticed, each way of registering a listener has an optional *priority* parameter.
# This value can be a positive or negative integer, with a default of `0` that controls the order in which each listener is executed.
# The higher the value, the sooner that listener would be executed.
# If two listeners have the same priority, they are executed in the order in which they were registered with the dispatcher.
#
# ```
# class MyEvent < AED::Event; end
#
# dispatcher = AED::EventDispatcher.new
# dispatcher.listener(MyEvent, priority: -10) { pp "callback1" }
# dispatcher.listener(MyEvent, priority: 10) { pp "callback2" }
# dispatcher.listener(MyEvent) { pp "callback3" }
# dispatcher.listener(MyEvent, priority: 20) { pp "callback4" }
# dispatcher.listener(MyEvent) { pp "callback5" }
#
# dispatcher.dispatch MyEvent.new
# # =>
# #   "callback4"
# #   "callback2"
# #   "callback3"
# #   "callback5"
# #   "callback1"
# ```
#
# NOTE: While the priority can be any `Int32`, best practices suggest keeping it in the `-255..255` range.
module Athena::EventDispatcher::EventDispatcherInterface
  # Dispatches the provided *event* to all listeners listening on that event.
  # Listeners are executed in priority order, highest first.
  abstract def dispatch(event : AED::Event) : AED::Event

  # Returns `true` if there are any listeners on any event.
  abstract def has_listeners? : Bool

  # Returns `true` if this dispatcher has any listeners on the provided *event_class*.
  abstract def has_listeners?(event_class : AED::Event.class) : Bool

  # Registers the provided *callable* listener to this dispatcher.
  abstract def listener(callable : AED::Callable) : AED::Callable

  # Registers the provided *callable* listener to this dispatcher, overriding its priority with that of the provided *priority*.
  abstract def listener(callable : AED::Callable, *, priority : Int32) : AED::Callable

  # Registers the block as an `AED::Callable` on the provided *event_class*, optionally with the provided *priority*.
  abstract def listener(event_class : E.class, *, priority : Int32 = 0, &block : E, AED::EventDispatcherInterface -> Nil) : AED::Callable forall E

  # Registers the provided *listener* instance to this dispatcher.
  abstract def listener(listener : AED::EventListenerInterface) : Nil

  # Returns a hash of all registered listeners as a `Hash(AED::Event.class, Array(AED::Callable))`.
  abstract def listeners : Hash(AED::Event.class, Array(AED::Callable))

  # Returns an `Array(AED::Callable)` for all listeners on the provided *event_class*.
  abstract def listeners(for event_class : AED::Event.class) : Array(AED::Callable)

  # Deregisters the provided *callable* from this dispatcher.
  #
  # TIP: The callable may be one retrieved via either `#listeners` method.
  abstract def remove_listener(callable : AED::Callable) : Nil

  # Deregisters listeners based on the provided *listener* from this dispatcher.
  abstract def remove_listener(listener : AED::EventListenerInterface) : Nil
end
