require "athena-dependency_injection"

require "./athena-validator"

require "./bundle/bundle"

# Registered apart from the bundle's definition so that the API docs can include the bundle without registering it.
ADI.register_bundle Athena::Validator::Bundle
