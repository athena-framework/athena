require "./config/config"
require "./cli"
require "./commands/*"

Athena::Cli.register_commands
