module Athena::Routing
  @[Athena::DI::Register]
  class RequestStack < Athena::DI::ClassService
    # The requests to be handled.
    getter requests = [] of HTTP::Server::Context
    getter actions = [] of Athena::Routing::Action

    # Returns the current request in the stack.
    def request : HTTP::Request
      @requests.last.request
    end

    # Returns the current response in the stack.
    def response : HTTP::Server::Response
      @requests.last.response
    end

    # The `Athena::Routing::Action` assoicated to the request.
    def action : Athena::Routing::Action
      @actions.last
    end
  end
end
