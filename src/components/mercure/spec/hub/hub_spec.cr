require "../spec_helper"

private URL = "https://demo.mercure.rocks/.well-known/mercure"

private class MockHTTPClient < HTTP::Client
  setter exception : ::Exception? = nil

  def post(path, headers : HTTP::Headers? = nil, *, form : String | IO) : HTTP::Client::Response
    if ex = @exception
      raise ex
    end

    path.should eq "/.well-known/mercure"
    headers.should eq HTTP::Headers{"authorization" => "Bearer FOO"}
    form.should eq "topic=https%3A%2F%2Fdemo.mercure.rocks%2Fdemo%2Fbooks%2F1.jsonld&data=Hi+from+Athena%21&private=on&id=id&retry=3"

    HTTP::Client::Response.new :ok, "ID"
  end
end

describe Athena::Mercure::Hub do
  describe "#publish" do
    it "happy path" do
      provider = AMC::TokenProvider::Static.new "FOO"
      hub = AMC::Hub.new URL, provider, http_client: MockHTTPClient.new URI.parse URL

      hub.publish(AMC::Update.new(
        "https://demo.mercure.rocks/demo/books/1.jsonld",
        "Hi from Athena!",
        true,
        "id",
        nil,
        3
      )).should eq "ID"
    end

    it "network issue" do
      provider = AMC::TokenProvider::Static.new "FOO"
      http_client = MockHTTPClient.new URI.parse URL
      http_client.exception = ::Exception.new "Oh noes"

      hub = AMC::Hub.new URL, provider, http_client: http_client

      expect_raises AMC::Exception::Runtime, "Failed to send an update." do
        hub.publish(AMC::Update.new(
          "https://demo.mercure.rocks/demo/books/1.jsonld",
          "Hi from Athena!",
          true,
          "id",
          nil,
          3
        ))
      end
    end
  end
end
