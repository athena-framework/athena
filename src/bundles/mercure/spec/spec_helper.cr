require "spec"

require "athena-spec"

require "../src/athena-mercure_bundle"

require "athena-mercure/src/spec"

ASPEC.run_all

def new_hub_registry(
  url : String = "https://example.com/.well-known/mercure",
  token_factory : AMC::TokenFactory::Interface? = AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000),
) : AMC::Hub::Registry
  AMC::Hub::Registry.new(AMC::Spec::MockHub.new(url, AMC::TokenProvider::Static.new("JWT"), token_factory: token_factory) { "ID" })
end

def new_request(
  *,
  method : String = "GET",
  path : String = "/",
  headers : ::HTTP::Headers = ::HTTP::Headers.new,
) : AHTTP::Request
  AHTTP::Request.new(method, path, headers)
end

def new_response_event(
  request : AHTTP::Request = new_request,
  response : AHTTP::Response = AHTTP::Response.new,
) : AHK::Events::Response
  AHK::Events::Response.new(request, response)
end
