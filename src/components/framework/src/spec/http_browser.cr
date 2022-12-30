# Simulates a browser and makes a requests to `ATH::RouteHandler`.
class Athena::Framework::Spec::HTTPBrowser < ATH::Spec::AbstractBrowser
  # Returns a reference to an `ADI::Spec::MockableServiceContainer` to allow configuring the container before a test.
  def container : ADI::Spec::MockableServiceContainer
    ADI.container.as(ADI::Spec::MockableServiceContainer)
  end

  protected def do_request(request : ATH::Request) : HTTP::Server::Response
    response = HTTP::Server::Response.new IO::Memory.new

    handler = ADI.container.athena_route_handler
    athena_response = handler.handle request

    athena_response.send request, response

    handler.terminate request, athena_response

    response
  end
end
