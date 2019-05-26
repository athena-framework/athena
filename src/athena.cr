require "./config/config"
require "./common/logger"
require "./cli"
require "./commands/*"

Athena::Cli.register_commands
