require "./spec_helper"

describe AMC::Discovery do
  it "preflight request" do
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000)
    ) { "ID" })

    request = HTTP::Request.new("OPTIONS", "/", headers: HTTP::Headers{"access-control-request-method" => "GET"})
    response = HTTP::Server::Response.new IO::Memory.new

    discovery = AMC::Discovery.new registry
    discovery.add_link request, response

    response.headers["link"]?.should be_nil
  end

  it "non-preflight request" do
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000)
    ) { "ID" })

    request = HTTP::Request.new("POST", "/")
    response = HTTP::Server::Response.new IO::Memory.new

    discovery = AMC::Discovery.new registry
    discovery.add_link request, response

    response.headers.get("link").should eq ["<https://example.com/.well-known/mercure>; rel=\"mercure\""]
  end
end
