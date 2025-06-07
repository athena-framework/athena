# An `ACTR::EventDispatcher::Event` whose processing may be interrupted when the event has been handled.
#
# `ACTR::EventDispatcher::Interface` implementations *MUST* check to determine if an `ACTR::EventDispatcher::Event` is marked as stopped after each listener is called.
# If it is, then the dispatcher should return immediately without calling any further listeners.
module Athena::Contracts::EventDispatcher::StoppableEvent
  @propagation_stopped : Bool = false

  # If future listeners should be executed.
  def propagate? : Bool
    !@propagation_stopped
  end

  # Prevent future listeners from executing once any listener calls `#stop_propagation`.
  def stop_propagation : Nil
    @propagation_stopped = true
  end
end
