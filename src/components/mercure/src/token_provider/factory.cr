require "./interface"

# A token provider implementation that provides the JWT via an [AMC::TokenFactory::Interface][] instance.
struct Athena::Mercure::TokenProvider::Factory
  include Athena::Mercure::TokenProvider::Interface

  def initialize(
    @factory : AMC::TokenFactory::Interface,
    @subscribe : Array(String) = [] of String,
    @publish : Array(String) = [] of String,
  ); end

  # :inherit:
  def jwt : String
    @factory.create @subscribe, @publish
  end
end
