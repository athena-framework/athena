# Allows for automatically discovering the Mercure hub via a [Link](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Link) header.
# E.g. can be included with the response for a resource to allow clients to then extract the URL from the rel `mercure` header to subscribe to future updates for that resource.
#
# See [Discovery](/Mercure/#discovery) for more information.
class Athena::Mercure::Discovery
  def initialize(
    @hub_registry : AMC::Hub::Registry,
  ); end

  # Adds the mercure relation `link` header to the provided *response*, optionally for the provided *hub_name*.
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
