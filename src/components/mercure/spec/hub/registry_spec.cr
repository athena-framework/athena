require "../spec_helper"

describe AMC::Hub::Interface do
  describe "#hub" do
    it "explicit name" do
      foo_hub = AMC::Spec::MockHub.new("https://foo.com", AMC::TokenProvider::Static.new("FOO")) { "foo" }
      bar_hub = AMC::Spec::MockHub.new("https://bar.com", AMC::TokenProvider::Static.new("BAR")) { "bar" }

      registry = AMC::Hub::Registry.new foo_hub, {"foo" => foo_hub, "bar" => bar_hub} of String => AMC::Hub::Interface

      registry.hub("bar").should eq bar_hub
    end

    it "default hub" do
      foo_hub = AMC::Spec::MockHub.new("https://foo.com", AMC::TokenProvider::Static.new("FOO")) { "foo" }
      bar_hub = AMC::Spec::MockHub.new("https://bar.com", AMC::TokenProvider::Static.new("BAR")) { "bar" }

      registry = AMC::Hub::Registry.new foo_hub, {"foo" => foo_hub, "bar" => bar_hub} of String => AMC::Hub::Interface

      registry.hub.should eq foo_hub
    end

    it "missing hub" do
      foo_hub = AMC::Spec::MockHub.new("https://foo.com", AMC::TokenProvider::Static.new("FOO")) { "foo" }

      registry = AMC::Hub::Registry.new foo_hub, {"foo" => foo_hub} of String => AMC::Hub::Interface

      expect_raises AMC::Exceptions::InvalidArgument, "No hub named 'baz' is available." do
        registry.hub "baz"
      end
    end
  end

  it "#hubs" do
    foo_hub = AMC::Spec::MockHub.new("https://foo.com", AMC::TokenProvider::Static.new("FOO")) { "foo" }
    bar_hub = AMC::Spec::MockHub.new("https://bar.com", AMC::TokenProvider::Static.new("BAR")) { "bar" }

    registry = AMC::Hub::Registry.new foo_hub, hubs = {"foo" => foo_hub, "bar" => bar_hub} of String => AMC::Hub::Interface

    registry.hubs.should eq hubs
  end
end
