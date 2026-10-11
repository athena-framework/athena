require "athena-dependency_injection"
require "athena-http_kernel"

require "./athena-mercure"

require "./bundle/bundle"
require "./bundle/authorization"
require "./bundle/discovery"
require "./bundle/listeners/*"

# Registered apart from the bundle's definition so that the API docs can include the bundle without configuring it.
ADI.register_bundle Athena::Mercure::Bundle
