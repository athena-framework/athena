require "CrSerializer"
require "./routing_config"

# Wrapper for the `athena.yml` config file.
module Athena::Config
  # Global config object for Athena.
  struct Config
    include CrSerializer(YAML)

    # :nodoc:
    def initialize; end

    # Config properties related to `Athena::Routing` module.
    getter routing : RoutingConfig = Athena::Config::RoutingConfig.new
  end
end
