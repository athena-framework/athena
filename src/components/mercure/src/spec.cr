module Athena::Mercure::Spec
  struct MockHub
    include Athena::Mercure::Hub::Interface

    getter url : String
    getter token_provider : AMC::TokenProvider::Interface
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

    def public_url : String
      @public_url || @url
    end

    def publish(update : AMC::Update) : String
      @publisher.call update
    end
  end

  class AssertingTokenFactory
    include AMC::TokenFactory::Interface

    getter? called : Bool = false

    def initialize(
      @token : String,
      @subscribe : Array(String)? = [] of String,
      @publish : Array(String)? = [] of String,
      @additional_claims : Hash(String, String) = {} of String => String
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
