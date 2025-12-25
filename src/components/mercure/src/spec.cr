# Provides helper types for testing `Athena::Mercure` related logic.
module Athena::Mercure::Spec
  # Similar to [AMC::Hub][] but does not make any requests to a real Mercure hub.
  # Instead, it accepts a block that can be used to make assertions against the related [AMC::Update][], and is expected to return the id of the related update.
  struct MockHub
    include Athena::Mercure::Hub::Interface

    # :inherit:
    getter url : String

    # :inherit:
    getter token_provider : AMC::TokenProvider::Interface

    # :inherit:
    getter token_factory : AMC::TokenFactory::Interface?

    @publisher : Proc(AMC::Update, String)

    def initialize(
      @url : String,
      @token_provider : AMC::TokenProvider::Interface,
      @public_url : String? = nil,
      @token_factory : AMC::TokenFactory::Interface? = nil,
      &@publisher : AMC::Update -> String
    )
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

  # An [AMC::TokenFactory::Interface][] implementation that will assert it was called with the expected arguments to `#create`.
  class AssertingTokenFactory
    include AMC::TokenFactory::Interface

    getter? called : Bool = false

    def initialize(
      @token : String,
      @subscribe : Array(String)? = [] of String,
      @publish : Array(String)? = [] of String,
      @additional_claims : Hash(String, String) = {} of String => String,
    )
    end

    def create(subscribe : Array(String) | ::Nil = [] of String, publish : Array(String) | ::Nil = [] of String, additional_claims : Hash | ::Nil = nil) : String
      subscribe.should eq @subscribe
      publish.should eq @publish
      additional_claims.should eq @additional_claims

      @token
    ensure
      @called = true
    end
  end
end
