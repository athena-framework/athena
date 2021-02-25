require "./cors_config"
require "./content_negotiation_config"

# Encompasses all configuration related to the `Athena::Routing` component.
#
# For a higher level introduction to configuring Athena components, see the [external documentation](/components/config).
struct Athena::Routing::Config
  # Configuration related to `Athena::Routing::Listeners::CORS`.
  #
  # See `ART::Config::CORS.configure`.
  getter cors : ART::Config::CORS? = ART::Config::CORS.configure

  # Configuration related to `ART::Listeners::Format`.
  #
  # Disables the listener if not defined.
  getter content_negotiation : ART::Config::ContentNegotiation? = ART::Config::ContentNegotiation.configure
end

class Athena::Config::Base
  # All configuration related to the `ART` component.
  getter routing : Athena::Routing::Config = Athena::Routing::Config.new
end
