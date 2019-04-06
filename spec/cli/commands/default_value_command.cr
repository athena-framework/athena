require "../cli_spec_helper"

struct DefaultValueCommand < Athena::Cli::Command
  self.name = "default"
  self.description = "Required param with a default value"

  def self.execute(path : String = "./") : String
    path.should be_a(String)
    path
  end
end
