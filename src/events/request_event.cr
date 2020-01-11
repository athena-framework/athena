# Emitted very early in the request's life-cycle; before the corresponding `ART::Route` (if any) has been resolved.
#
# This event can be listened on to add information to the request, or return a response before even triggering the router; `ART::Listeners::Cors` is an example of this.
class Athena::Routing::Events::Request < AED::Event
  include Athena::Routing::Events::Context

  # If `#request` has been fufilled.
  getter? request_finished : Bool = false

  # Marks that `#request` is fufilled and that `#response` should be returned.
  #
  # Propagation of `self` will stop once `#finish_request` is called.
  def finish_request : Nil
    @request_finished = true
    stop_propagation
  end
end
