# Provides helper types for testing `Athena::Mercure` related logic.
module Athena::Mercure::Spec
  # Similar to `AMC::Hub` but does not make any requests to a real Mercure hub.
  # Instead, it accepts a block that can be used to make assertions against the related `AMC::Update`, and is expected to return the id of the related update.
  struct MockHub
    include Athena::Mercure::Hub::Interface

    # :inherit:
    getter url : String

    # :inherit:
    getter token_provider : AMC::TokenProvider::Interface

    # :inherit:
    getter token_factory : AMC::TokenFactory::Interface?

    # :inherit:
    getter protocol_version : AMC::ProtocolVersion

    # :inherit:
    getter cookie_name : String

    @publisher : Proc(AMC::Update, String)

    def initialize(
      @url : String,
      @token_provider : AMC::TokenProvider::Interface,
      @public_url : String? = nil,
      @token_factory : AMC::TokenFactory::Interface? = nil,
      cookie_name : String? = nil,
      @protocol_version : AMC::ProtocolVersion = :v1,
      &@publisher : AMC::Update -> String
    )
      @cookie_name = cookie_name || @protocol_version.default_cookie_name
    end

    # :inherit:
    def public_url : String
      @public_url || @url
    end

    # :inherit:
    def publish(update : AMC::Update) : String
      @publisher.call update
    end
  end

  # An `AMC::TokenFactory::Interface` implementation that will assert it was called with the expected arguments to `#create`.
  class AssertingTokenFactory
    include AMC::TokenFactory::Interface

    getter? called : Bool = false

    def initialize(
      @token : String,
      @grants : Array(AMC::Grant) = [] of AMC::Grant,
      @additional_claims : Hash(String, String) = {} of String => String,
    )
    end

    def create(grants : Array(AMC::Grant) = [] of AMC::Grant, additional_claims : Hash | ::Nil = nil) : String
      grants.should eq @grants
      # No additional claims are equivalent to an empty hash of them.
      (additional_claims || {} of String => String).should eq @additional_claims

      @token
    ensure
      @called = true
    end
  end
end
