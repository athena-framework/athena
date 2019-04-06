require "./cli_spec_helper"

to_s = <<-TOS
Command
\tto_s - Command to test .to_s on
Usage
\t./YOUR_BINARY -c to_s [arguments]
Arguments
\t--optional : (String | Nil)
\t--required : Bool
\t--path : String = "./"\n
TOS

describe Athena::Cli::Command do
  describe "when parsing args from a command" do
    describe "that are required" do
      context "with one param" do
        it "should convert correctly" do
          CreateUserCommand.command.call(["--id=123"]).should eq 100
          CreateUserCommand.command.call(["--id 123"]).should eq 100
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
          MultiParamCommand.command.call(["--one=foo", "--three 3.14", "--two=8"]).should eq "foo is 11.14"
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--two="] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--two"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14", "--t"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.command.call ["--one=foo", "--three=3.14"] }
        end
      end

      context "with a default value" do
        it "should use default value if no value is given" do
          DefaultValueCommand.command.call([] of String).should eq "./"
        end

        it "should use given value" do
          DefaultValueCommand.command.call(["--path=/user/config"]).should eq "/user/config"
          DefaultValueCommand.command.call(["--path /user/config"]).should eq "/user/config"
        end
      end

      context "with an array param" do
        it "should convert correctly" do
          ArrayBoolCommand.command.call(["--bools=true,false,false,true"]).should eq [true, false, false, true]
          ArrayBoolCommand.command.call(["--bools true,false,false,true"]).should eq [true, false, false, true]
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

  describe ".to_s" do
    it "should print correctly" do
      ToSCommand.to_s.should eq to_s
    end
  end
end
