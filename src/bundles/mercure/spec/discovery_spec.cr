require "./spec_helper"

struct DiscoveryTest < ASPEC::TestCase
  def test_add_link : Nil
    discovery = ABM::Discovery.new new_hub_registry
    request = new_request

    discovery.add_link request

    links = request.attributes.get? "_links", Array(String)
    links.should eq [%(<https://example.com/.well-known/mercure>; rel="mercure")]
  end

  def test_add_link_with_named_hub : Nil
    hub = AMC::Spec::MockHub.new(
      "https://hub1.example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
    ) { "ID" }

    registry = AMC::Hub::Registry.new(hub, {"hub1" => hub.as(AMC::Hub::Interface)})
    discovery = ABM::Discovery.new registry
    request = new_request

    discovery.add_link request, "hub1"

    links = request.attributes.get? "_links", Array(String)
    links.should eq [%(<https://hub1.example.com/.well-known/mercure>; rel="mercure")]
  end

  def test_add_link_accumulates_multiple_links : Nil
    hub1 = AMC::Spec::MockHub.new(
      "https://hub1.example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
    ) { "ID" }

    hub2 = AMC::Spec::MockHub.new(
      "https://hub2.example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
    ) { "ID" }

    registry = AMC::Hub::Registry.new(hub1, {
      "hub1" => hub1.as(AMC::Hub::Interface),
      "hub2" => hub2.as(AMC::Hub::Interface),
    })

    discovery = ABM::Discovery.new registry
    request = new_request

    discovery.add_link request, "hub1"
    discovery.add_link request, "hub2"

    links = request.attributes.get? "_links", Array(String)
    links.should eq [
      %(<https://hub1.example.com/.well-known/mercure>; rel="mercure"),
      %(<https://hub2.example.com/.well-known/mercure>; rel="mercure"),
    ]
  end

  def test_add_link_skips_preflight_request : Nil
    discovery = ABM::Discovery.new new_hub_registry
    request = new_request(method: "OPTIONS", headers: ::HTTP::Headers{"access-control-request-method" => "GET"})

    discovery.add_link request

    request.attributes.has?("_links").should be_false
  end
end
