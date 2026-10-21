require "./interface"

# A token provider implementation that provides the JWT via an `AMC::TokenFactory::Interface` instance.
# The JWT is allowed the provided *grants*, and includes the provided *additional_claims*.
struct Athena::Mercure::TokenProvider::Factory
  include Athena::Mercure::TokenProvider::Interface

  def initialize(
    @factory : AMC::TokenFactory::Interface,
    @grants : Array(AMC::Grant) = [] of AMC::Grant,
    @additional_claims : Hash(String, String | Array(String)) = {} of String => String | Array(String),
  ); end

  # :inherit:
  def jwt : String
    @factory.create @grants, @additional_claims
  end
end
