module Athena::Mercure::TokenFactory::Interface
  abstract def create(
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil
  ) : String
end
