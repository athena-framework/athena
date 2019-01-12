require "./cli_spec_helper"

describe Athena::Cli::Command do
  describe "when parsing args from a command" do
    describe "with one param" do
      it "should convert correctly" do
        IO.pipe do |r, w|
          SpecHelper.logger = Logger.new w

          CreateUserCommand.run ["--id=123"], CreateUserCommand

          r.gets.should match /I, \[.*\]  INFO -- : CreateUserCommand Success/
        end
      end
    end

    describe "with multiple params" do
      it "should convert correctly" do
        IO.pipe do |r, w|
          SpecHelper.logger = Logger.new w

          MultiParamCommand.run ["--one=foo", "--two=8", "--three=3.14"], MultiParamCommand

          r.gets.should match /I, \[.*\]  INFO -- : MultiParamCommand Success/
        end
      end
    end
  end
end
