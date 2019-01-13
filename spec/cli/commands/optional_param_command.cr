require "../cli_spec_helper"

struct OptionalParamCommand < Athena::Cli::Command
  self.command_name = "optional"
  self.description = "optional string"

  def self.execute(u : String?, g : Array(Float32)?) : Nil
    it "should pass params correctly" do
      u.should be_a String?
      g.should be_a Array(Float32)?
    end
  end
end
