require "../cli_spec_helper"

struct NoParamsCommand < Athena::Cli::Command
  self.name = "no_params"
  self.description = "No params"

  def self.execute : String
    "foo"
  end
end
