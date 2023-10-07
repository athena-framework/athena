require "./cors"
require "./content_negotiation"
require "./view_handler"

# Encompasses all configuration related to the `Athena::Framework` component.
#
# For a higher level introduction to configuring Athena components, see the [external documentation](../../architecture/config.md).
struct Athena::Framework::Config
  # Configuration related to `ATH::Listeners::CORS`.
  #
  # See `ATH::Config::CORS.configure`.
  getter cors : ATH::Config::CORS? = ATH::Config::CORS.configure

  # Configuration related to `ATH::Listeners::Format`.
  #
  # See `ATH::Config::ContentNegotiation.configure`.
  getter content_negotiation : ATH::Config::ContentNegotiation? = ATH::Config::ContentNegotiation.configure

  # Configuration related to `ATH::Listeners::View`.
  #
  # See `ATH::Config::ViewHandler.configure`.
  getter view_handler : ATH::Config::ViewHandler = ATH::Config::ViewHandler.configure
end

class Athena::Config::Base
  # All configuration related to the `ART` component.
  getter routing : Athena::Framework::Config = Athena::Framework::Config.new
end
