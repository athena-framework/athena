require "./interface"

struct Athena::Mercure::TokenProvider::Factory
  include Athena::Mercure::TokenProvider::Interface

  def initialize(
    @factory : AMC::TokenFactory::Interface,
    @subscribe : Array(String) = ["*"],
    @publish : Array(String) = ["*"],
  ); end

  def jwt : String
    @factory.create @subscribe, @publish
  end
end
