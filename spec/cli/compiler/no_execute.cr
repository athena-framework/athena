require "../cli_spec_helper"

struct NoExecuteCommand < Athena::Cli::Command
  self.name = "no:execute"
  self.description = "Command with no execute method"
end
