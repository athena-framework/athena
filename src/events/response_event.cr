class Athena::Routing::Events::Response < AED::Event
  getter request : HTTP::Request
  getter response : HTTP::Server::Response

  def initialize(ctx : HTTP::Server::Context)
    @request = ctx.request
    @response = ctx.response
  end
end
