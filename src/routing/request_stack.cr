module Athena::Routing
  @[Athena::DI::Register]
  class RequestStack < Athena::DI::ClassService
    getter requests = [] of HTTP::Server::Context

    # Returns the current request in the stack.
    def request : HTTP::Request
      @requests.last.request
    end

    # Returns the current response in the stack.
    def response : HTTP::Server::Response
      @requests.last.response
    end
  end
end
