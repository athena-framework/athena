require "yaml"
require "./routing_config"

# Wrapper for the `athena.yml` config file.
module Athena::Config
  # Global config object for Athena.
  struct Config
    include YAML::Serializable

    # :nodoc:
    # TODO Remove after https://github.com/crystal-lang/crystal/issues/7557 is resolved.
    def initialize; end

    # Config properties related to `Athena::Routing` module.
    getter routing : RoutingConfig = Athena::Config::RoutingConfig.new
  end
end
