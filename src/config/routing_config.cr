require "./cors_config"

module Athena::Config
  # Config properties related to `Athena::Routing` module.
  struct RoutingConfig
    include CrSerializer(YAML)

    # :nodoc:
    def initialize; end

    # Config properites specific to CORS.
    @[Assert::Valid]
    getter cors : CorsConfig = Athena::Config::CorsConfig.new
  end
end
