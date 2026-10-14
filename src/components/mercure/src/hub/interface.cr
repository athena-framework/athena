class Athena::Mercure::Hub; end

# Represents the API that a Mercure hub instance must implement.
module Athena::Mercure::Hub::Interface
  # Returns the internal URL of this hub used to publish updates.
  abstract def url : String

  # Returns the public URL of this hub used to subscribe.
  abstract def public_url : String

  # Returns the `AMC::TokenProvider::Interface` associated with this hub.
  abstract def token_provider : AMC::TokenProvider::Interface?

  # Returns the `AMC::TokenFactory::Interface` associated with this hub.
  abstract def token_factory : AMC::TokenFactory::Interface?

  # Returns the version of the Mercure protocol this hub speaks.
  abstract def protocol_version : AMC::ProtocolVersion

  # Returns the name of the cookie subscribers of this hub are authorized with.
  abstract def cookie_name : String

  # Publishes the provided *update* to this hub.
  abstract def publish(update : AMC::Update) : String
end
