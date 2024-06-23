require "../../spec_helper"

describe ACON::Input::Value::Bool do
  describe "#get" do
    describe Bool do
      it "non-nilable" do
        val = ACON::Input::Value::Bool.new(false).get Bool
        typeof(val).should eq Bool
        val.should be_false
      end

      it "nilable" do
        val = ACON::Input::Value::Bool.new(true).get Bool?
        typeof(val).should eq Bool?
        val.should be_true
      end
    end

    describe String do
      it "non-nilable" do
        val = ACON::Input::Value::Bool.new(false).get String
        typeof(val).should eq String
        val.should eq "false"
      end

      it "nilable" do
        val = ACON::Input::Value::Bool.new(true).get String?
        typeof(val).should eq String?
        val.should eq "true"
      end
    end

    describe Int do
      it "non-nilable" do
        expect_raises ACON::Exception::Logic, "'false' is not a valid 'Int32'." do
          ACON::Input::Value::Bool.new(false).get Int32
        end

        expect_raises ACON::Exception::Logic, "'true' is not a valid 'UInt8'." do
          ACON::Input::Value::Bool.new(true).get UInt8
        end
      end

      it "nilable" do
        expect_raises ACON::Exception::Logic, "'false' is not a valid '(Int32 | Nil)'." do
          ACON::Input::Value::Bool.new(false).get Int32?
        end

        expect_raises ACON::Exception::Logic, "'true' is not a valid '(UInt8 | Nil)'." do
          ACON::Input::Value::Bool.new(true).get UInt8?
        end
      end
    end

    describe Float do
      it "non-nilable" do
        expect_raises ACON::Exception::Logic, "'false' is not a valid 'Float32'." do
          ACON::Input::Value::Bool.new(false).get Float32
        end

        expect_raises ACON::Exception::Logic, "'true' is not a valid 'Float64'." do
          ACON::Input::Value::Bool.new(true).get Float64
        end
      end

      it "nilable" do
        expect_raises ACON::Exception::Logic, "'false' is not a valid '(Float32 | Nil)'." do
          ACON::Input::Value::Bool.new(false).get Float32?
        end

        expect_raises ACON::Exception::Logic, "'true' is not a valid '(Float64 | Nil)'." do
          ACON::Input::Value::Bool.new(true).get Float64?
        end
      end
    end

    describe Array do
      describe String do
        it "non-nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid 'Array(String)'." do
            ACON::Input::Value::Bool.new(false).get Array(String)
          end
        end

        it "nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid '(Array(String) | Nil)'." do
            ACON::Input::Value::Bool.new(false).get Array(String)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exception::Logic, "'true' is not a valid '(Array(String | Nil) | Nil)'." do
            ACON::Input::Value::Bool.new(true).get Array(String?)?
          end
        end
      end

      describe Int32 do
        it "non-nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid 'Array(Int32)'." do
            ACON::Input::Value::Bool.new(false).get Array(Int32)
          end
        end

        it "nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid '(Array(Int32) | Nil)'." do
            ACON::Input::Value::Bool.new(false).get Array(Int32)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exception::Logic, "'true' is not a valid '(Array(Int32 | Nil) | Nil)'." do
            ACON::Input::Value::Bool.new(true).get Array(Int32?)?
          end
        end
      end

      describe Bool do
        it "non-nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid 'Array(Bool)'." do
            ACON::Input::Value::Bool.new(false).get Array(Bool)
          end
        end

        it "nilable" do
          expect_raises ACON::Exception::Logic, "'false' is not a valid '(Array(Bool) | Nil)'." do
            ACON::Input::Value::Bool.new(false).get Array(Bool)?
          end
        end

        it "nilable generic value" do
          expect_raises ACON::Exception::Logic, "'true' is not a valid '(Array(Bool | Nil) | Nil)'." do
            ACON::Input::Value::Bool.new(true).get Array(Bool?)?
          end
        end
      end
    end
  end
end
