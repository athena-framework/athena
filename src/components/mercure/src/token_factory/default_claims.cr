require "./interface"

# Decorates a token factory, adding the provided *default_claims* to every token it creates, unless the claim is provided when creating the token.
#
# Useful for claims every token of a hub requires, such as `iss`, `sub`, `client_id`, and `aud` under the Mercure protocol 1.0, so code creating tokens indirectly, such as `AMC::Authorization`, does not need to repeat them.
class Athena::Mercure::TokenFactory::DefaultClaims
  include Athena::Mercure::TokenFactory::Interface

  def initialize(
    @decorated : AMC::TokenFactory::Interface,
    @default_claims : Hash(String, String | Array(String)),
  ); end

  # :inherit:
  def create(
    grants : Array(AMC::Grant) = [] of AMC::Grant,
    additional_claims : Hash? = nil,
  ) : String
    @decorated.create grants, additional_claims ? @default_claims.merge(additional_claims) : @default_claims
  end
end
