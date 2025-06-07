require "./stoppable_event"

# An event consists of a subclass of this type, usually with extra context specific information.
# The metaclass of the event type is used as a unique identifier, which generally should end in a verb that indicates what action has been taken.
#
# ```
# # Define a custom event
# class ExceptionRaisedEvent < ACTR::EventDispatcher::Event
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
# The base event type includes `ACTR::EventDispatcher::StoppableEvent` that enables this behavior.
# Checkout the related module for more information.
abstract class Athena::Contracts::EventDispatcher::Event
  include Athena::Contracts::EventDispatcher::StoppableEvent
end
