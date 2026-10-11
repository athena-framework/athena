# Adds Mercure hub `Link` headers that was stored in the request attributes via `AMC::Bundle::Discovery`.
struct Athena::Mercure::Bundle::Listeners::AddLinkHeader
  # :nodoc:
  def initialize; end

  @[AEDA::AsEventListener]
  def on_response(event : AHK::Events::Response) : Nil
    return unless links = event.request.attributes.get? "_links", Array(String)

    # TODO: Create WebLink component?
    links.each do |link|
      event.response.headers.add "link", link
    end
  end
end
