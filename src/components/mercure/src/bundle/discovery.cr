# Extension of `AMC::Discovery` that accepts [AHTTP::Request](/HTTP/Request/)
# and stores the link in a request attribute for the `AMC::Bundle::Listeners::AddLinkHeader` listener.
class Athena::Mercure::Bundle::Discovery < AMC::Discovery
  def initialize(
    hub_registry : AMC::Hub::Registry,
  )
    super
  end

  # Adds the mercure relation `link` header to the provided *request*, optionally for the provided *hub_name*.
  def add_link(request : AHTTP::Request, hub_name : String? = nil) : Nil
    return if self.preflight_request? request.request

    hub = @hub_registry.hub hub_name

    # TODO: Create WebLink component?
    links = request.attributes.get?("_links", Array(String)) || Array(String).new
    links << self.generate_link(hub.public_url)
    request.attributes.set("_links", links, Array(String))
  end
end
