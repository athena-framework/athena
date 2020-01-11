require "./cors_config"

# Encompasses all configuration related to the `Athena::Routing` component.
#
# For a higher level introduction to configuring Athena components, see `Athena::Config`.
struct Athena::Routing::Config
  include ACF::Configuration

  # Configuration related to `Athena::Routing::Listeners::Cors`.
  #
  # Disables the listener if not defined.
  getter cors : ART::Config::Cors? = nil
end

struct Athena::Config::Base
  # All configuration related to the `ART` component.
  getter routing : Athena::Routing::Config = Athena::Routing::Config.new
end
