require "../cli_spec_helper"

struct ToSCommand < Athena::Cli::Command
  self.name = "to_s"
  self.description = "Command to test .to_s on"

  def self.execute(optional : String?, required : Bool, path : String = "./") : String
    path
  end
end
