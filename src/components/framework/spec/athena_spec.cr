require "./spec_helper"

private class MockHandler
  include HTTP::Handler

  def call(context)
  end
end

describe Athena::Framework do
  describe ".from_parameter" do
    describe Number do
      it Int64 do
        Int64.from_parameter("123").should eq 123_i64
      end

      it "Int with whitespace" do
        expect_raises ArgumentError, "Invalid Int32" do
          Int32.from_parameter("   123")
        end
      end

      it Float32 do
        Float32.from_parameter("3.14").should eq 3.14_f32
      end

      it "Float with whitespace" do
        expect_raises ArgumentError, "Invalid Float64" do
          Float64.from_parameter("   123.5")
        end
      end
    end

    describe Bool do
      it "true" do
        Bool.from_parameter("true").should be_true
        Bool.from_parameter("on").should be_true
        Bool.from_parameter("1").should be_true
        Bool.from_parameter("yes").should be_true
      end

      it "false" do
        Bool.from_parameter("false").should be_false
        Bool.from_parameter("off").should be_false
        Bool.from_parameter("0").should be_false
        Bool.from_parameter("no").should be_false
      end

      it "invalid" do
        expect_raises ArgumentError, "Invalid Bool" do
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
        expect_raises ArgumentError, "Invalid Nil" do
          Nil.from_parameter("foo")
        end
      end
    end
  end

  describe ".from_parameter?" do
    describe Number do
      it Int64 do
        Int64.from_parameter?("123").should eq 123_i64
      end

      it "Int with whitespace" do
        Int32.from_parameter?("   123").should be_nil
      end

      it Float32 do
        Float32.from_parameter?("3.14").should eq 3.14_f32
      end

      it "Float with whitespace" do
        Float64.from_parameter?("   123.5").should be_nil
      end
    end

    describe Bool do
      it "true" do
        Bool.from_parameter?("true").should be_true
        Bool.from_parameter?("on").should be_true
        Bool.from_parameter?("1").should be_true
        Bool.from_parameter?("yes").should be_true
      end

      it "false" do
        Bool.from_parameter?("false").should be_false
        Bool.from_parameter?("off").should be_false
        Bool.from_parameter?("0").should be_false
        Bool.from_parameter?("no").should be_false
      end

      it "invalid" do
        Bool.from_parameter?("foo").should be_nil
      end
    end

    it Object do
      str = "foo"

      String.from_parameter?(str).should be str
    end

    describe Array do
      it "single type" do
        Array(Int32).from_parameter?([1, 2]).should eq [1, 2]
      end

      it "Union type" do
        Array(Int32 | Bool).from_parameter?([1, false]).should eq [1, false]
      end
    end

    describe Nil do
      it "valid" do
        Nil.from_parameter?("null").should be_nil
      end

      it "invalid" do
        Nil.from_parameter?("foo").should be_nil
      end
    end
  end

  describe ATH::Server do
    describe ".new" do
      it "creates a server with the provided args" do
        ATH::Server.new 1234, "google.com", false
      end

      it "creates a server with a prepended HTTP::Handler" do
        ATH::Server.new prepend_handlers: [MockHandler.new]
      end

      it "creates a server with SSL context" do
        context = OpenSSL::SSL::Context::Server.new
        context.certificate_chain = "#{__DIR__}/assets/openssl/openssl.crt"
        context.private_key = "#{__DIR__}/assets/openssl/openssl.key"

        ATH::Server.new ssl_context: context
      end
    end
  end
end
