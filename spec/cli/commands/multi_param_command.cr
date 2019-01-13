require "../cli_spec_helper"

struct MultiParamCommand < Athena::Cli::Command
  self.command_name = "multi"
  self.description = "Has multiple required params"

  def self.execute(one : String, two : Int8, three : Float64) : String
    it "should pass params correctly" do
      one.should be_a String
      one.should eq "foo"

      two.should be_a Int8
      two.should eq 8

      three.should be_a Float64
      three.should eq 3.14
    end
    "#{one} is #{two + three}"
  end
end
