# A token factory is responsible for creating the token used to authenticate requests to the Mercure hub.
module Athena::Mercure::TokenFactory::Interface
  # Returns a JWT token that has access to *subscribe* and *publish* to the provided topics.
  # Optionally, *additional_claims* may be added to the JWT.
  abstract def create(
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
  ) : String
end
