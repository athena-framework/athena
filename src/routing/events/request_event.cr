class Athena::Routing::Events::Request < AED::Event
  getter request : HTTP::Request
  getter response : HTTP::Server::Response

  getter set_response : HTTP::Server::Response? = nil

  def initialize(ctx : HTTP::Server::Context)
    @request = ctx.request
    @response = ctx.response
  end

  # Sets the *response* that should be returned for this `#request`.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def set_response : Nil
    stop_propagation
  end
end
