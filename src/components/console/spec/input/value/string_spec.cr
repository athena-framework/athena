require "../../spec_helper"

describe ACON::Input::Value::String do
  describe "#get" do
    describe Bool do
      describe "non-nilable" do
        it "true" do
          val = ACON::Input::Value::String.new("true").get Bool
          typeof(val).should eq Bool
          val.should be_true
        end

        it "false" do
          val = ACON::Input::Value::String.new("false").get Bool
          typeof(val).should eq Bool
          val.should be_false
        end

        it "invalid" do
          expect_raises ACON::Exception::Logic, "'123' is not a valid 'Bool'." do
            ACON::Input::Value::String.new("123").get Bool
          end
        end
      end

      describe "nilable" do
        it "valid" do
          val = ACON::Input::Value::String.new("true").get Bool?
          typeof(val).should eq Bool?
          val.should be_true
        end

        it "invalid" do
          expect_raises ACON::Exception::Logic, "'123' is not a valid 'Bool?'." do
            ACON::Input::Value::String.new("123").get Bool?
          end
        end
      end
    end

    describe String do
      it "non-nilable" do
        val = ACON::Input::Value::String.new("foo").get String
        typeof(val).should eq String
        val.should eq "foo"
      end

      it "nilable" do
        val = ACON::Input::Value::String.new("foo").get String?
        typeof(val).should eq String?
        val.should eq "foo"
      end
    end

    describe Int do
      it "non-nilable" do
        string = ACON::Input::Value::String.new "123"

        val = string.get Int32
        typeof(val).should eq Int32
        val.should eq 123

        val = string.get(UInt8)
        typeof(val).should eq UInt8
        val.should eq 123_u8
      end

      it "nilable" do
        string = ACON::Input::Value::String.new "123"

        val = string.get Int32?
        typeof(val).should eq Int32?
        val.should eq 123

        val = string.get UInt8?
        typeof(val).should eq UInt8?
        val.should eq 123_u8
      end

      it "non number" do
        expect_raises ACON::Exception::Logic, "'foo' is not a valid 'Int32'." do
          ACON::Input::Value::String.new("foo").get Int32
        end

        expect_raises ACON::Exception::Logic, "'foo' is not a valid 'Int32'." do
          ACON::Input::Value::String.new("foo").get Int32?
        end
      end
    end

    describe Float do
      it "non-nilable" do
        string = ACON::Input::Value::String.new "4.57"

        val = string.get Float64
        typeof(val).should eq Float64
        val.should eq 4.57

        val = string.get Float32
        typeof(val).should eq Float32
        val.should eq 4.57_f32
      end

      it "nilable" do
        string = ACON::Input::Value::String.new "4.57"

        val = string.get Float64?
        typeof(val).should eq Float64?
        val.should eq 4.57

        val = string.get Float32?
        typeof(val).should eq Float32?
        val.should eq 4.57_f32
      end

      it "non number" do
        expect_raises ACON::Exception::Logic, "'foo' is not a valid 'Float64'." do
          ACON::Input::Value::String.new("foo").get Float64
        end

        expect_raises ACON::Exception::Logic, "'foo' is not a valid 'Float64'." do
          ACON::Input::Value::String.new("foo").get Float64?
        end
      end
    end

    describe Array do
      describe String do
        it "non-nilable" do
          val = ACON::Input::Value::String.new("foo,bar,baz").get Array(String)
          typeof(val).should eq Array(String)
          val.should eq ["foo", "bar", "baz"]
        end

        it "nilable" do
          val = ACON::Input::Value::String.new("foo,bar,baz").get Array(String)?
          typeof(val).should eq Array(String)?
          val.should eq ["foo", "bar", "baz"]
        end

        it "nilable generic value" do
          val = ACON::Input::Value::String.new("foo,bar,baz").get Array(String?)?
          typeof(val).should eq Array(String?)?
          val.should eq ["foo", "bar", "baz"]
        end
      end

      describe Int32 do
        it "non-nilable" do
          val = ACON::Input::Value::String.new("1,2,3").get Array(Int32)
          typeof(val).should eq Array(Int32)
          val.should eq [1, 2, 3]
        end

        it "nilable" do
          val = ACON::Input::Value::String.new("1,2,3").get Array(Int32)?
          typeof(val).should eq Array(Int32)?
          val.should eq [1, 2, 3]
        end

        it "nilable generic value" do
          val = ACON::Input::Value::String.new("1,2,3").get Array(Int32?)?
          typeof(val).should eq Array(Int32?)?
          val.should eq [1, 2, 3]
        end
      end

      describe Bool do
        it "non-nilable" do
          val = ACON::Input::Value::String.new("false,true,true").get Array(Bool)
          typeof(val).should eq Array(Bool)
          val.should eq [false, true, true]
        end

        it "nilable" do
          val = ACON::Input::Value::String.new("false,true,true").get Array(Bool)?
          typeof(val).should eq Array(Bool)?
          val.should eq [false, true, true]
        end

        it "nilable generic value" do
          val = ACON::Input::Value::String.new("false,true,true").get Array(Bool?)?
          typeof(val).should eq Array(Bool?)?
          val.should eq [false, true, true]
        end
      end
    end
  end
end
