class Athena::Mercure::Hub; end

module Athena::Mercure::Hub::Interface
  abstract def url : String
  abstract def public_url : String
  abstract def token_provider : AMC::TokenProvider::Interface
  abstract def token_factory : AMC::TokenFactory::Interface?
  abstract def publish(update : AMC::Update) : String
end
