require "./cors_config"

struct Athena::Routing::Config
  include ACF::Configuration

  # Configuration related to `Athena::Routing::Listeners::Cors`.
  #
  # Disables the listener if not defined.
  getter cors : ART::Config::Cors? = nil
end

struct Athena::Config::Base
  getter routing : Athena::Routing::Config
end
