require "option_parser"

require "./common/types"

require "./cli/command"
require "./cli/registry"

# Athena module containing elements for:
# * Creating CLI commands.
module Athena::Cli
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
        Athena::Cli::Registry.find(name).command.call ARGV
        exit
      end
    end
  end
end
