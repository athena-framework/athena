module Athena::Routing
  @[Athena::DI::Register]
  # Contains the current request, response, and action.
  # Allows for them to be injected into other classes via DI.
  class RequestStack < Athena::DI::ClassService
    # :nodoc:
    getter requests = [] of HTTP::Server::Context

    # :nodoc:
    getter actions = [] of Athena::Routing::Action

    # Returns the current request.
    def request : HTTP::Request
      @requests.last.request
    end

    # Returns the current response.
    def response : HTTP::Server::Response
      @requests.last.response
    end

    # Returns the current `Athena::Routing::RouteAction`.
    def action : Athena::Routing::Action
      @actions.last
    end
  end
end
