require "./cors_config"

module Athena::Config
  # Config properties related to `Athena::Routing` module.
  struct RoutingConfig
    include YAML::Serializable

    # :nodoc:
    # TODO Remove after https://github.com/crystal-lang/crystal/issues/7557 is resolved.
    def initialize; end

    # Whether the `CorsHandler` should be invoked.
    getter enable_cors : Bool = false

    # Config properites specific to CORS.
    getter cors : CorsConfig = Athena::Config::CorsConfig.new
  end
end
