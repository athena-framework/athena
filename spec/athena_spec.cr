require "./spec_helper"

describe Athena::Routing do
  describe ".from_parameter" do
    describe Number do
      it Int64 do
        Int64.from_parameter("123").should eq 123_i64
      end

      it Float32 do
        Float32.from_parameter("3.14").should eq 3.14_f32
      end
    end

    describe Bool do
      it "true" do
        Bool.from_parameter("true").should be_true
      end

      it "false" do
        Bool.from_parameter("false").should be_false
      end

      it "invalid" do
        expect_raises ArgumentError, "Invalid Bool: foo" do
          Bool.from_parameter("foo")
        end
      end
    end

    it Object do
      str = "foo"

      String.from_parameter(str).should be str
    end

    describe Array do
      it "single type" do
        Array(Int32).from_parameter([1, 2]).should eq [1, 2]
      end

      it "Union type" do
        Array(Int32 | Bool).from_parameter([1, false]).should eq [1, false]
      end
    end

    describe Nil do
      it "valid" do
        Nil.from_parameter("null").should be_nil
      end

      it "invalid" do
        expect_raises ArgumentError, "Invalid Nil: foo" do
          Nil.from_parameter("foo")
        end
      end
    end
  end

  describe ART::Server do
    describe "#initialize" do
      it "creates a server with the provided args" do
        ART::Server.new 1234, "google.com", false
      end
    end
  end
end
