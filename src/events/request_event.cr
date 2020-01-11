# This event is emitted early in the request's life-cycle; before the corresponding `ART::Route` (if any) has been resolved.
#
# It can be used to add information to the request, or return a response before even triggering the router; `ART::Listeners::Cors` is an example of this.
#
# Athena adds a `HTTP::Request#attributes` getter that returns a `Hash(String, Bool | Int32 | String)` which can be used to store simple information that can be used later.
class Athena::Routing::Events::Request < AED::Event
  # Returns the current request object.
  getter request : HTTP::Request

  # Returns the current response object.
  getter response : HTTP::Server::Response

  # If `#request` has been fufilled.
  getter? request_finished : Bool = false

  def initialize(ctx : HTTP::Server::Context)
    @request = ctx.request
    @response = ctx.response
  end

  # Marks that `#request` is fufilled and that `#response` should be returned.
  #
  # Propagation of `self` will stop once `#finish_request` is called.
  def finish_request : Nil
    @request_finished = true
    stop_propagation
  end
end
