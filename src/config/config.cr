require "./cors"
require "./content_negotiation"
require "./view_handler"

# Encompasses all configuration related to the `Athena::Routing` component.
#
# For a higher level introduction to configuring Athena components, see the [external documentation](/components/config).
struct Athena::Routing::Config
  # Configuration related to `ART::Listeners::CORS`.
  #
  # See `ART::Config::CORS.configure`.
  getter cors : ART::Config::CORS? = ART::Config::CORS.configure

  # Configuration related to `ART::Listeners::Format`.
  #
  # See `ART::Config::ContentNegotiation.configure`.
  getter content_negotiation : ART::Config::ContentNegotiation? = ART::Config::ContentNegotiation.configure

  # Configuration related to `ART::Listeners::View`.
  #
  # See `ART::Config::ViewHandler.configure`.
  getter view_handler : ART::Config::ViewHandler = ART::Config::ViewHandler.configure
end

class Athena::Config::Base
  # All configuration related to the `ART` component.
  getter routing : Athena::Routing::Config = Athena::Routing::Config.new
end
