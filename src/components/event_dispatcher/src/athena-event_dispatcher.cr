require "./event_dispatcher"

# Convenience alias to make referencing `Athena::EventDispatcher` types easier.
alias AED = Athena::EventDispatcher

# A [Mediator](https://en.wikipedia.org/wiki/Mediator_pattern) and [Observer](https://en.wikipedia.org/wiki/Observer_pattern)
# pattern event library.
#
# `Athena::EventDispatcher` or, `AED` for short, allows defining instance methods on `EventListenerInterface` types (observers) that will be executed
# when an `Event` is dispatched via the `EventDispatcher` (mediator).
#
# All events are registered with an `EventDispatcher` at compile time.  While the recommended usage involves using
# listener structs, it is also possible to add/remove event handlers dynamically at runtime.  The `EventDispatcher` has two constructors;
# one that supports manual or DI initialization, while the other auto registers listeners at compile time via macros.
#
# An event is nothing more than a `class` that, optionally, contains stateful information about the event.  For example a `HttpOnRequest` event would
# contain a reference to the `HTTP::Request` object so that the listeners have access to request data.  Similarly, a `HttpOnResponse` event
# would contain a reference to the `HTTP::Server::Response` object so that the response body/headers/status can be mutated by the listeners.
#
# Since events and listeners are registered at compile time (via macros or DI), listeners can be added to a project seamlessly without updating any configuration, or having
# to instantiate a `HTTP::Handler` object and add it to an array for example.  The main benefit of this is that an external shard that defines a listener could
# be installed and would inherently be picked up and used by `Athena::EventDispatcher`; thus making an application easily extendable.
#
# ### Example
# ```
# # Create a custom event.
# class ExceptionEvent < AED::Event
#   property? handled : Bool = false
#
#   getter exception : Exception
#
#   # Events can contain stateful information related to the event.
#   def initialize(@exception : Exception); end
# end
#
# # Create a listener.
# struct ExceptionListener
#   include AED::EventListenerInterface
#
#   # Define what events `self` is listening on as well as their priorities.
#   #
#   # The higher the priority the sooner that specific listener is executed.
#   def self.subscribed_events : AED::SubscribedEvents
#     AED::SubscribedEvents{
#       ExceptionEvent => 0,
#     }
#   end
#
#   # Listener handler's are `#call` instance methods restricted to the type of event it should handle.
#   #
#   # Multiple methods can be defined to handle multiple events within the same listener.
#   #
#   # Event handler's also have access to the dispatcher instance itself.
#   def call(event : ExceptionEvent, dispatcher : AED::EventDispatcherInterface) : Nil
#     # Do something with the `ExceptionEvent` and/or dispatcher
#     event.handled = true
#   end
# end
#
# # New up an `AED::EventDispatcher`, using `AED::EventDispatcher#new`.
# # This overload automatically registers listeners using macros.
# #
# # See also `AED::EventDispatcher#new(listeners : Array(EventListenerInterface))` for a more manual/DI friendly initializer.
# dispatcher = AED::EventDispatcher.new
#
# # Instantiate our custom event.
# event = ExceptionEvent.new ArgumentError.new("Test exception")
#
# # All events are dispatched via an `AED::EventDispatcher` instance.
# #
# # Similarly, all listeners are registered with it.
# dispatcher.dispatch event
#
# event.handled # => true
#
# # Additional methods also exist on the dispatcher, such as:
# # * Adding/removing listeners at runtime
# # * Checking the priority of a listener
# # * Getting an array of listeners for a given event
# # * Checking if there is a listener(s) listening on a given `AED::Event`
# dispatcher.has_listeners? ExceptionEvent # => true
# ```
module Athena::EventDispatcher
  VERSION = "0.1.0"

  # The possible types an event listener can be.  `AED::EventListenerInterface` instances use `#call`
  # in order to keep a common interface with the `Proc` based listeners.
  alias EventListenerType = EventListenerInterface | Proc(Event, EventDispatcherInterface, Nil)

  # The mapping of the `AED::Event` and the priority a `AED::EventListenerInterface` is listening on.
  #
  # See `AED::EventListenerInterface`.
  alias SubscribedEvents = Hash(AED::Event.class, Int32)

  # Wraps an `EventListenerType` in order to keep track of its `priority`.
  struct EventListener
    # :nodoc:
    delegate :call, :==, to: @listener

    # The wrapped `EventListenerType` instance.
    getter listener : EventListenerType

    # The priority of the `EventListenerType` instance.
    #
    # The higher the `priority` the sooner `listener` will be executed.
    getter priority : Int32 = 0

    def initialize(@listener : EventListenerType, @priority : Int32 = 0); end
  end

  # Creates a listener for the provided *event*.  The macro's block is used as the listener.
  #
  # The macro *block* implicitly yields `event` and `dispatcher`.
  #
  # ```
  # listener = AED.create_listener(SampleEvent) do
  #   # Do something with the event.
  #   event.some_method
  #
  #   # A reference to the `AED::EventDispatcherInterface` is also provided.
  #   dispatcher.dispatch FakeEvent.new
  # end
  # ```
  macro create_listener(event, &)
    Proc(AED::Event, AED::EventDispatcherInterface, Nil).new do |event, dispatcher|
      Proc({{event.id}}, AED::EventDispatcherInterface, Nil).new do |event, dispatcher|
        {{yield}}
      end.call event.as({{event}}), dispatcher
    end
  end
end
