require "../cli_spec_helper"

struct MultiParamCommand < Athena::Cli::Command
  def self.execute(one : String, two : Int8, three : Float64) : Nil
    it "should pass params correctly" do
      one.should be_a String
      one.should eq "foo"

      two.should be_a Int8
      two.should eq 8

      three.should be_a Float64
      three.should eq 3.14

      SpecHelper.logger.info "MultiParamCommand Success"
    end
  end
end
