require "./cli_spec_helper"

describe Athena::Cli::Command do
  describe "when parsing args from a command" do
    describe "with one param" do
      it "should convert correctly" do
        CreateUserCommand.execute.call(["--id=123"]).should eq 100
      end
    end

    describe "with multiple params" do
      it "should convert correctly" do
        MultiParamCommand.execute.call(["--one=foo", "--two=8", "--three=3.14"]).should eq "foo is 11.14"
      end
    end
  end
end
