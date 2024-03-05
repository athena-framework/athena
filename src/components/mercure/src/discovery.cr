class Athena::Mercure::Discovery
  def initialize(
    @hub_registry : AMC::Hub::Registry
  ); end

  def add_link(request : HTTP::Request, response : HTTP::Server::Response, hub_name : String? = nil) : Nil
    return if self.preflight_request? request

    hub = @hub_registry.hub hub_name

    # TODO: Create WebLink component?
    response.headers.add "link", %(<#{hub.public_url}>; rel="mercure")
  end

  private def preflight_request?(request : HTTP::Request) : Bool
    "options" == request.method.downcase && request.headers.has_key? "access-control-request-method"
  end
end
