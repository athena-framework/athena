require "./cli_spec_helper"

describe Athena::Cli::Command do
  describe "when parsing args from a command" do
    describe "that are required" do
      context "with one param" do
        it "should convert correctly" do
          CreateUserCommand.command.call(["--id=123"]).should eq 100
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.command.call(["--id="]) }
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.command.call(["--id"]) }
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.command.call(["--i"]) }
        end
      end

      context "with multiple params" do
        it "should convert correctly" do
          MultiParamCommand.command.call(["--one=foo", "--three=3.14", "--two=8"]).should eq "foo is 11.14"
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--two="] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--two"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--t"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14"] }
        end
      end

      context "with an array param" do
        it "should convert correctly" do
          ArrayBoolCommand.command.call(["--bools=true,false,false,true"]).should eq [true, false, false, true]
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.command.call ["--bools="] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.command.call ["--bools"] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.command.call ["--bos"] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.command.call [] of String }
        end
      end
    end

    describe "that are optional" do
      it "should return nil if missing" do
        OptionalParamCommand.command.call(["--u=123"]).should be_nil
        OptionalParamCommand.command.call(["--u"]).should be_nil
        OptionalParamCommand.command.call(["--"]).should be_nil
        OptionalParamCommand.command.call(["--foo"]).should be_nil
        OptionalParamCommand.command.call(["--g=1.2,1.1"]).should be_nil
      end
    end
  end
end
