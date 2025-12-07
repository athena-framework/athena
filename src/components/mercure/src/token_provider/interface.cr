# A token provider is responsible for providing the token used to authenticate requests to the Mercure hub.
module Athena::Mercure::TokenProvider::Interface
  # Returns the JWT token used to authenticate requests to the Mercure hub.
  abstract def jwt : String
end
