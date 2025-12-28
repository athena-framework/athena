require "./spec_helper"

private class MockHandler
  include ::HTTP::Handler

  def call(context)
  end
end

describe Athena::Framework do
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
