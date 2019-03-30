require "./cors_options"

module Athena::Config
  # Config properties related to CORS.
  @[CrSerializer::ClassOptions(raise_on_invalid: true)]
  struct CorsConfig
    include CrSerializer

    # :nodoc:
    def initialize; end

    # Whether the `CorsHandler` should be invoked.
    getter enabled : Bool = false

    # Strategy to use.
    @[Assert::Choice(choices: ["blacklist", "whitelist"], message: "'{{actual}}' is not a valid strategy. Valid strategies are: {{choices}}")]
    getter strategy : String = "blacklist"

    getter defaults : CorsOptions = Athena::Config::CorsOptions.new(true)

    getter groups : Hash(String, CorsOptions) = {} of String => Athena::Config::CorsOptions
  end
end
