module Athena::Contracts::EventDispatcher::Interface
  # Dispatches the provided *event* to all listeners listening on that event.
  # Listeners are executed in priority order, highest first.
  #
  # The listener _MUST_ return the provided *event*.
  abstract def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
end
