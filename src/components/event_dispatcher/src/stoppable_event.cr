# An `AED::Event` whose processing may be interrupted when the event has been handled.
#
# `AED::EventDispatcherInterface` implementations *MUST* check to determine if an `AED::Event`
# is marked as stopped after each listener is called.  If it is, then the `AED::EventListenerType` should
# return immediately without calling any further `AED::EventListenerType`.
module Athena::EventDispatcher::StoppableEvent
  @propatation_stopped : Bool = false

  # If future `AED::EventListenerType` should be executed.
  def propagate? : Bool
    !@propatation_stopped
  end

  # Prevent future `AED::EventListenerType` from executing once
  # any listener calls `#stop_propagation` on `self`.
  def stop_propagation : Nil
    @propatation_stopped = true
  end
end
