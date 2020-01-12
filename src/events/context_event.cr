# Represents an event that has access to both the request and response objects.
module Athena::Routing::Events::Context
  # Returns the current request object.
  getter request : HTTP::Request

  # Returns the current response object.
  getter response : HTTP::Server::Response

  def initialize(ctx : HTTP::Server::Context)
    @request = ctx.request
    @response = ctx.response
  end
end
