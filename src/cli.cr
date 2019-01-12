require "option_parser"

require "./common/types"

require "./cli/command"
require "./cli/registry"

# Athena module containg elements for:
# * `Command` - Define CLI commands
module Athena::Cli
  # :nodoc:
  private abstract struct Arg; end

  # :nodoc:
  private record Argument(T) < Arg, name : String, optional : Bool, type : T.class = T

  # Defines an option parser interfance for Athena CLI commands
  macro register_commands
    OptionParser.parse! do |parser|
      parser.banner = "Usage: YOUR_BINARY [arguments]"
      parser.on("-h", "--help", "Show this help") { puts parser; exit }
      parser.on("-l", "--list", "Lists commands registered with athena") { puts Athena::Cli::Registry.to_s; exit }
      parser.on("-c NAME", "--command=NAME", "Runs a command with the given name") do |name|
        commandClass : Athena::Cli::Command.class | Nil = Athena::Cli::Registry.commands.find { |c| c.command_name == name }
        raise "No command with the name #{name} has been registered" if commandClass.nil?
        commandClass.execute.call ARGV
        exit
      end
    end
  end
end
