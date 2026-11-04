require "athena-dependency_injection"

require "./http"

require "./bundle/bundle"
require "./bundle/firewall_context"
require "./bundle/firewall_map"
require "./bundle/compiler_passes/*"

# Registered apart from the bundle's definition so that the API docs can include the bundle without configuring it.
ADI.register_bundle Athena::Security::Bundle
