require "./cors_config"

# Encompasses all configuration related to the `Athena::Routing` component.
#
# For a higher level introduction to configuring Athena components, see `Athena::Config`.
struct Athena::Routing::Config
  # Configuration related to `Athena::Routing::Listeners::CORS`.
  #
  # Disables the listener if not defined.
  getter cors : ART::Config::CORS? = ART::Config::CORS.configure
end

class Athena::Config::Base
  # All configuration related to the `ART` component.
  getter routing : Athena::Routing::Config = Athena::Routing::Config.new
end
