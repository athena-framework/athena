class Athena::Routing::Events::Request < AED::Event
  getter request : HTTP::Request
  getter response : HTTP::Server::Response

  getter? request_finished : Bool = false

  def initialize(ctx : HTTP::Server::Context)
    @request = ctx.request
    @response = ctx.response
  end

  # Sets the *response* that should be returned for this `#request`.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def finish_request : Nil
    @request_finished = true
    stop_propagation
  end
end
