# A token factory is responsible for creating the token used to authenticate requests to the Mercure hub.
module Athena::Mercure::TokenFactory::Interface
  # Returns a JWT token that is allowed the provided *grants*, such as to subscribe or publish to some topics.
  # Optionally, *additional_claims* may be added to the JWT.
  abstract def create(
    grants : Array(AMC::Grant) = [] of AMC::Grant,
    additional_claims : Hash? = nil,
  ) : String
end
