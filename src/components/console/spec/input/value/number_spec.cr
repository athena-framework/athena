require "../../spec_helper"

describe ACON::Input::Value::Number do
  describe "#get" do
    describe Bool do
      it "non-nilable" do
        expect_raises ACON::Exceptions::Logic, "'123' is not a valid 'Bool'." do
          ACON::Input::Value::Number.new(123).get Bool
        end
      end

      it "nilable" do
        expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Bool | Nil)'." do
          ACON::Input::Value::Number.new(123).get Bool?
        end
      end
    end

    describe String do
      it "non-nilable" do
        val = ACON::Input::Value::Number.new(123).get String
        typeof(val).should eq String
        val.should eq "123"
      end

      it "nilable" do
        val = ACON::Input::Value::Number.new(123).get String?
        typeof(val).should eq String?
        val.should eq "123"
      end
    end

    describe Int do
      it "non-nilable" do
        val = ACON::Input::Value::Number.new(123).get Int32
        typeof(val).should eq Int32
        val.should eq 123

        val = ACON::Input::Value::Number.new(123_u8).get UInt8
        typeof(val).should eq UInt8
        val.should eq 123_u8
      end

      it "non-nilable" do
        val = ACON::Input::Value::Number.new(123).get Int32?
        typeof(val).should eq Int32?
        val.should eq 123

        val = ACON::Input::Value::Number.new(123_u8).get UInt8?
        typeof(val).should eq UInt8?
        val.should eq 123_u8
      end
    end

    describe Float do
      it "non-nilable" do
        val = ACON::Input::Value::Number.new(4.69).get Float32
        typeof(val).should eq Float32
        val.should eq 4.69_f32

        val = ACON::Input::Value::Number.new(4.69).get Float64
        typeof(val).should eq Float64
        val.should eq 4.69
      end

      it "non-nilable" do
        val = ACON::Input::Value::Number.new(4.69).get Float32?
        typeof(val).should eq Float32?
        val.should eq 4.69_f32

        val = ACON::Input::Value::Number.new(4.69).get Float64?
        typeof(val).should eq Float64?
        val.should eq 4.69
      end
    end

    describe Array do
      describe String do
        it "non-nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid 'Array(String)'." do
            ACON::Input::Value::Number.new(123).get Array(String)
          end
        end

        it "nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(String) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(String)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(String | Nil) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(String?)?
          end
        end
      end

      describe Int32 do
        it "non-nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid 'Array(Int32)'." do
            ACON::Input::Value::Number.new(123).get Array(Int32)
          end
        end

        it "nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(Int32) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(Int32)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(Int32 | Nil) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(Int32?)?
          end
        end
      end

      describe Bool do
        it "non-nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid 'Array(Bool)'." do
            ACON::Input::Value::Number.new(123).get Array(Bool)
          end
        end

        it "nilable" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(Bool) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(Bool)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exceptions::Logic, "'123' is not a valid '(Array(Bool | Nil) | Nil)'." do
            ACON::Input::Value::Number.new(123).get Array(Bool?)?
          end
        end
      end
    end
  end
end
