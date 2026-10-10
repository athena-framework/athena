require "athena-contracts/service"
require "athena-dependency_injection"

require "./athena-orm"

require "./bundle/bundle"
require "./bundle/registry"

# Registered apart from the bundle's definition so that the API docs can include the bundle without configuring it.
ADI.register_bundle Athena::ORM::Bundle
