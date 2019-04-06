require "../cli_spec_helper"

struct MultiParamCommand < Athena::Cli::Command
  self.name = "params:multi"
  self.description = "Has multiple required params"

  def self.execute(one : String, two : Int8, three : Float64) : String
    one.should be_a String
    one.should eq "foo"

    two.should be_a Int8
    two.should eq 8

    three.should be_a Float64
    three.should eq 3.14
    "#{one} is #{two + three}"
  end
end
