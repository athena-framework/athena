# Represents the most basic interface that event dispatchers must implement.
# Can be further extended to provide additional functionality.
#
# All dispatchers:
#
# * _MUST_ call listeners synchronously
# * _MUST_ return the same even object it was originally passed.
# * _MUST NOT_ return until all listeners have executed.
# * _MUST_ handle the case where the provided *event* is a [ACTR::EventDispatcher::StoppableEvent][].
module Athena::Contracts::EventDispatcher::Interface
  # Dispatches the provided *event* to all listeners listening on that event.
  abstract def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
end
