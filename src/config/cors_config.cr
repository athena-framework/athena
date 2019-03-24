require "./cors_options"

module Athena::Config
  # Config properties related to CORS.
  struct CorsConfig
    include YAML::Serializable

    # :nodoc:
    # TODO Remove after https://github.com/crystal-lang/crystal/issues/7557 is resolved.
    def initialize; end

    property defaults : CorsOptions = Athena::Config::CorsOptions.new(true)

    property groups : Hash(String, CorsOptions) = {} of String => Athena::Config::CorsOptions
  end
end
