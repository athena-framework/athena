# An `AED::Event` whose processing may be interrupted when the event has been handled.
#
# `AED::EventDispatcherInterface` implementations *MUST* check to determine if an `AED::Event` is marked as stopped after each listener is called.
# If it is, then the dispatcher should return immediately without calling any further listeners.
#
# ```
# class MyEvent < AED::Event; end
#
# dispatcher = AED::EventDispatcher.new
#
# dispatcher.listener(MyEvent) { pp "callback1" }
# dispatcher.listener(MyEvent) { |e| pp "callback2"; e.stop_propagation }
# dispatcher.listener(MyEvent) { pp "callback3" }
#
# dispatcher.dispatch MyEvent.new
# # =>
# #   "callback1"
# #   "callback2"
# ```
module Athena::EventDispatcher::StoppableEvent
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
