require "./annotations"
require "./event_dispatcher"
require "./generic_event"

# Convenience alias to make referencing `Athena::EventDispatcher` types easier.
alias AED = Athena::EventDispatcher

# Convenience alias to make referencing `AED::Annotations` types easier.
alias AEDA = AED::Annotations

# # Introduction
#
# Object-oriented code has helped a lot in ensuring code extensibility.
# By having classes with well defined responsibilities, it becomes more flexible and easily extendable to modify their behavior.
# However inheritance has its limits is not the best option when these modifications need to be shared between other modified subclasses.
# Say for example you want to do something before and after a method is executed, without interfering with the other plugins.
#
# The `Athena::EventDispatcher` component is a [Mediator](https://en.wikipedia.org/wiki/Mediator_pattern) and [Observer](https://en.wikipedia.org/wiki/Observer_pattern) pattern event library.
# This pattern allows creating very flexibly and truly extensible applications.
#
# A good example of this is the [architecture](/components) of Athena Framework itself.
# Once an `ATH::Response` has been created by a controller, it may be useful to allow additional modifications before it is actually returned to the client.
# Such modifications could include adding additional headers, paginating the data itself, or capturing performance metrics to name a few.
# To handle this, the framework itself makes use of `Athena::EventDispatcher` to dispatch an event that notifies all registered listeners on that event.
# From which, they could make any necessary modifications seamlessly without affecting the framework logic itself, or the other listeners.
#
# ## Usage
# ```
# # Create a custom event.
# class ExceptionRaisedEvent < AED::Event
#   property? handled : Bool = false
#
#   getter exception : Exception
#
#   # Events can contain stateful information related to the event.
#   def initialize(@exception : Exception); end
# end
#
# dispatcher = AED::EventDispatcher.new
#
# # Register a listener directly with the dispatcher
# dispatcher.listener ExceptionRaisedEvent do |event|
#   pp event.exception.message
# end
#
# # Or use a dedicated type for more complex use cases.
# class ExceptionListener
#   include AED::EventListenerInterface
#
#   @[AEDA::AsEventListener]
#   # Multiple methods can be defined to handle multiple events within the same listener,
#   # and/or to share state via instance variables between listener methods on different events.
#   def on_exception(event : ExceptionRaisedEvent) : Nil
#     # Do something with the event`
#     event.handled = true
#   end
# end
#
# dispatcher.listener ExceptionListener.new
#
# # Instantiate our custom event.
# event = ExceptionRaisedEvent.new ArgumentError.new("Test exception")
#
# dispatcher.dispatch event
# # =>
# #   "Test exception"
#
# event.handled? # => true
# ```
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/architecture/event_dispatcher) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-event_dispatcher:
#     github: athena-framework/event-dispatcher
#     version: ~> 0.2.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-event_dispatcher"`.
#
# From here you will want to create your `AED::Event`s classes.
# You will then need a way to create/register the listeners with an `AED::EventDispatcherInterface`.
#
# The dispatcher should be created in a way that allows it to be used throughout the application such that any mutations that happen to the listeners are reflected on subsequent dispatches.
#
# WARNING: If using this component within the context of something that handles independent execution flows, such as a web framework, you will want there to be a dedicated dispatcher instance for each path.
# This ensures that one flow will not leak state to any other flow, while still allowing flow specific mutations to be used.
# Consider pairing this component with the [Athena::DependencyInjection][Athena::DependencyInjection--getting-started] component as a way to handle this.
#
# TIP: If using this component with the `Athena::DependencyInjection` component, `AED::EventListenerInterface` that have the `ADI::Register` annotation will automatically
# be registered with the default `AED::EventDispatcherInterface`.
module Athena::EventDispatcher
  VERSION = "0.2.0"

  # Contains all the `Athena::EventDispatcher` based annotations.
  module Annotations; end
end
