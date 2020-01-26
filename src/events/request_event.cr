require "./request_aware"

# Emitted very early in the request's life-cycle; before the corresponding `ART::Route` (if any) has been resolved.
#
# This event can be listened on to add information to the request, or return a response before even triggering the router; `ART::Listeners::CORS` is an example of this.
class Athena::Routing::Events::Request < AED::Event
  include Athena::Routing::Events::RequestAware

  # The response object.
  getter response : ART::Response? = nil

  def response=(@response : ART::Response) : Nil
    stop_propagation
  end
end
