require "../cli_spec_helper"

struct ArrayBoolCommand < Athena::Cli::Command
  self.command_name = "array"
  self.description = "Array of bools"

  def self.execute(bools : Array(Bool)) : Array(Bool)
    it "should pass params correctly" do
      bools.should be_a(Array(Bool))
      bools.should eq [true, false, false, true]
    end
    bools
  end
end
