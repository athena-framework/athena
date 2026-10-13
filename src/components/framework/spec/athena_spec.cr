require "./spec_helper"

private class MockHandler
  include ::HTTP::Handler

  def call(context)
  end
end

describe Athena::Framework do
  it "runs without OpenSSL, zlib, or libmagic", tags: "compiled" do
    ASPEC::Methods.assert_executes <<-'CR', flags: ["without_openssl", "without_zlib", "without_libmagic"]
      require "../src/athena"
      require "../src/spec"

      class ExampleController < ATH::Controller
        @[ARTA::Get("/")]
        def index : String
          "OK"
        end
      end

      struct WithoutSystemLibrariesTest < ATH::Spec::APITestCase
        def test_request : Nil
          self.get("/").body.should eq %("OK")
        end
      end

      ASPEC.run_all

      ATH::Server.new
    CR
  end

  describe ATH::Server do
    describe ".new" do
      it "creates a server with the provided args" do
        ATH::Server.new 1234, "google.com", false
      end

      it "creates a server with a prepended ::HTTP::Handler" do
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
