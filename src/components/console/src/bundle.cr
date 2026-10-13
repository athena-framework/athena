require "athena-dependency_injection"

require "./athena-console"

require "./bundle/bundle"
require "./bundle/application"
require "./bundle/compiler_passes/register_commands"
require "./bundle/container_command_loader"

# Registered apart from the bundle's definition so that the API docs can include the bundle without registering it.
ADI.register_bundle Athena::Console::Bundle
