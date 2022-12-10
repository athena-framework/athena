require "./annotations"
require "./event_dispatcher"
require "./generic_event"

# Convenience alias to make referencing `Athena::EventDispatcher` types easier.
alias AED = Athena::EventDispatcher

# Convenience alias to make referencing `AED::Annotations` types easier.
alias AEDA = AED::Annotations

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
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/components/event_dispatcher) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-event_dispatcher:
#     github: athena-framework/event-dispatcher
#     version: ~> 0.1.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-event_dispatcher"`.
#
# From here you will want to define any `AED::EventListenerInterface` and/or custom `AED::Event`s as required by your application.
# You will then need a way to create/register the listeners with an `AED::EventDispatcherInterface`.
# If none of your listeners have any constructor arguments, you can most likely just call `.new` on the default implementation,
# otherwise you will need to pass it an array of the instantiated listener types.
#
# The dispatcher should be created in a way that allows it to be used throughout the application such that any mutations that happen to the listeners are reflected on subsequent dispatches.
#
# WARNING: If using this component within the context of something that handles independent execution flows, such as a web framework, you will want there to be a dedicated dispatcher instance for each path.
# This ensures that one flow will not leak state to any other flow, while still allowing flow specific mutations to be used.
# Consider pairing this component with the [Athena::DependencyInjection][Athena::DependencyInjection--getting-started] component as a way to handle this.
module Athena::EventDispatcher
  VERSION = "0.1.4"

  # Contains all the `Athena::EventDispatcher` based annotations.
  module Annotations; end
end
