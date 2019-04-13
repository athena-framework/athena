require "./cli_spec_helper"

to_s = <<-TOS
Command
\tto_s - Command to test .to_s on
Usage
\t./YOUR_BINARY -c to_s [arguments]
Arguments
\toptional : (String | Nil)
\trequired : Bool
\tpath : String = "./"\n
TOS

describe Athena::Cli::Command do
  describe "when parsing args from a command" do
    describe "when there are none" do
      it "should not try to parse arguments" do
        NoParamsCommand.run_command([] of String).should eq "foo"
        NoParamsCommand.run_command(["--id=123"]).should eq "foo"
        NoParamsCommand.run_command(["--one=foo", "--three=3.14", "--two="]).should eq "foo"
      end
    end

    describe "that are required" do
      context "with one param" do
        it "should convert correctly" do
          CreateUserCommand.run_command(["--id=123"]).should eq 100
          CreateUserCommand.run_command(["--id 123"]).should eq 100
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.run_command ["--id="] }
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.run_command ["--id"] }
          expect_raises Exception, "Required argument 'id' was not supplied" { CreateUserCommand.run_command ["--i"] }
        end
      end

      context "with multiple params" do
        it "should convert correctly" do
          MultiParamCommand.run_command(["--one=foo", "--three=3.14", "--two=8"]).should eq "foo is 11.14"
          MultiParamCommand.run_command(["--one=foo", "--three 3.14", "--two=8"]).should eq "foo is 11.14"
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.run_command ["--one=foo", "--three=3.14", "--two="] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.run_command ["--one=foo", "--three=3.14", "--two"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.run_command ["--one=foo", "--three=3.14", "--t"] }
          expect_raises Exception, "Required argument 'two' was not supplied" { MultiParamCommand.run_command ["--one=foo", "--three=3.14"] }
        end
      end

      context "with a default value" do
        it "should use default value if no value is given" do
          DefaultValueCommand.run_command([] of String).should eq "./"
        end
      end

      context "without a default value" do
        it "should use given value" do
          DefaultValueCommand.run_command(["--path=/user/config"]).should eq "/user/config"
          DefaultValueCommand.run_command(["--path /user/config"]).should eq "/user/config"
        end
      end

      context "with an array param" do
        it "should convert correctly" do
          ArrayBoolCommand.run_command(["--bools=true,false,false,true"]).should eq [true, false, false, true]
          ArrayBoolCommand.run_command(["--bools true,false,false,true"]).should eq [true, false, false, true]
        end

        it "should raise if missing" do
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.run_command ["--bools="] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.run_command ["--bools"] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.run_command ["--bos"] }
          expect_raises Exception, "Required argument 'bools' was not supplied" { ArrayBoolCommand.run_command [] of String }
        end
      end
    end

    describe "that are optional" do
      it "should return nil if missing" do
        OptionalParamCommand.run_command(["--u=123"]).should be_nil
        OptionalParamCommand.run_command(["--u"]).should be_nil
        OptionalParamCommand.run_command(["--"]).should be_nil
        OptionalParamCommand.run_command(["--foo"]).should be_nil
        OptionalParamCommand.run_command(["--g=1.2,1.1"]).should be_nil
      end
    end
  end

  describe ".to_s" do
    it "should print correctly" do
      ToSCommand.to_s.should eq to_s
    end
  end
end
