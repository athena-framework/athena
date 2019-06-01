require "option_parser"

require "./common/types"
require "./common/logger"

require "./cli/command"
require "./cli/registry"

# Override the logger to simply use STDOUT
protected def Athena.configure_logger
  Crylog.configure do |registry|
    registry.register "main" do |logger|
      logger.handlers = [Crylog::Handlers::IOHandler.new(STDOUT)] of Crylog::Handlers::LogHandler
    end
  end
end

# Athena module containing elements for:
# * Creating CLI commands.
module Athena::Cli
  # Set the logger to use for CLI commands.
  Athena.configure_logger

  # Defines an option parser interface for Athena CLI commands.
  macro register_commands
    OptionParser.parse! do |parser|
      parser.banner = "Usage: YOUR_BINARY [arguments]"
      parser.on("-h", "--help", "Show this help") { puts parser; exit }
      parser.on("-l", "--list", "List available commands") { puts Athena::Cli::Registry.to_s; exit }
      parser.on("-e COMMAND", "--explain COMMAND", "Show more detailed help for a specific command") do |name|
        puts Athena::Cli::Registry.find(name).to_s
        exit
       end
      parser.on("-c NAME", "--command=NAME", "Run a command with the given name") do |name|
        Athena::Cli::Registry.find(name).run_command ARGV
        exit
      end
    end
  end
end
