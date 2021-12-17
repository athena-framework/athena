require "./stoppable_event"

# Base `class` for all event objects.
#
# This event does not contain any event data and
# can be used by events that do not require any state.
#
# Can be inherited from to include information about the event.
#
# NOTE: If one event inherits from another, and both are being used within a listener; the child event's handler would be executed twice since its type is compatible with the parent.
# Either use composition versus inheritance for sharing common logic between events, or add an explicit type check in the listener.
#
# ```
# # Define a custom event
# class ExceptionEvent < AED::Event
#   getter exception : Exception
#
#   def initialize(@exception : Exception); end
# end
#
# # Using Event on its own
# dispatcher.dispatch AED::Event.new
#
# # Dispatch a custom event
# exception = ArgumentError.new "Value cannot be negative"
# dispatcher.dispatch ExceptionEvent.new exception
# ```
class Athena::EventDispatcher::Event
  include Athena::EventDispatcher::StoppableEvent
end
