# Base type of an event dispatcher.  Defines how dispatchers should be implemented.
module Athena::EventDispatcher::EventDispatcherInterface
  # Adds the provided *listener* as a listener for *event*, optionally with the provided *priority*.
  abstract def add_listener(event : AED::Event.class, listener : AED::EventListenerType, priority : Int32) : Nil

  # Dispatches *event* to all listeners registered on `self` that are listening on that event.
  #
  # `AED::EventListenerInterface`'s are executed based on the listener's priority; the higher the value the sooner it gets executed.
  abstract def dispatch(event : AED::Event) : Nil

  # Returns the listeners listening on the provided *event*.
  # If no *event* is provided, returns all listeners.
  abstract def listeners(event : AED::Event.class | Nil) : Array(AED::EventListener)

  # Returns the *listener* priority for the provided *event*.  Returns `nil` if no listeners are listening on the provided *event* or
  # if *listener* isn't listening on *event*.
  abstract def listener_priority(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Int32?

  # Returns `true` if there are any listeners listening on the provided *event*.
  # If no *event* is provided, returns `true` if there are *ANY* listeners registered on `self`.
  abstract def has_listeners?(event : AED::Event.class | Nil) : Bool

  # Removes the provided *event* from the provided *listener*.
  abstract def remove_listener(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Nil

  # :ditto:
  abstract def remove_listener(event : AED::Event.class, listener : AED::EventListenerType) : Nil
end
