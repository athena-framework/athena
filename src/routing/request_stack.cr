module Athena::Routing
  @[Athena::DI::Register]
  class RequestStack
    include Athena::DI::Service

    getter request : HTTP::Request?
    getter response : HTTP::Server::Response?

    def add(context : HTTP::Server::Context)
      @request = context.request
      @response = context.respo
    end
  end
end
