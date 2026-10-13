require "./spec_helper"

describe AMC::Bundle, tags: "compiled" do
  describe "with multiple hubs" do
    it "provides every hub via the registry" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        ADI.configure({
          mercure: {
            hubs: {
              first: {
                url: "https://first.example.com/.well-known/mercure",
                jwt: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
              },
              second: {
                url: "https://second.example.com/.well-known/mercure",
                jwt: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class RegistryConsumer
          getter registry : AMC::Hub::Registry

          def initialize(@registry : AMC::Hub::Registry); end
        end

        registry = ADI.container.registry_consumer.registry

        raise "Expected the default hub to be the first hub" unless registry.hub.url == "https://first.example.com/.well-known/mercure"
        raise "Expected the second hub to be available" unless registry.hub("second").url == "https://second.example.com/.well-known/mercure"
      CR
    end

    it "registers named token aliases for every hub" do
      ASPEC::Methods.assert_compiles <<-'CR', preamble: %(require "./spec_helper.cr")
        ADI.configure({
          mercure: {
            hubs: {
              first: {
                url: "https://first.example.com/.well-known/mercure",
                jwt: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
              },
              second: {
                url: "https://second.example.com/.well-known/mercure",
                jwt: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              factory_aliases = ADI::ServiceContainer::ALIASES[Athena::Mercure::TokenFactory::Interface].map { |a| {a["name"], a["id"]} }
              provider_aliases = ADI::ServiceContainer::ALIASES[Athena::Mercure::TokenProvider::Interface].map { |a| {a["name"], a["id"]} }
            %}
            ASPEC.compile_time_assert(\{{ factory_aliases.includes?({"first_token_factory", "mercure_hub_first_jwt_factory_default_claims"}) }}, "Expected a named token factory alias for the first hub")
            ASPEC.compile_time_assert(\{{ factory_aliases.includes?({"second_token_factory", "mercure_hub_second_jwt_factory_default_claims"}) }}, "Expected a named token factory alias for the second hub")
            ASPEC.compile_time_assert(\{{ provider_aliases.includes?({"first_token_provider", "mercure_hub_first_jwt_provider"}) }}, "Expected a named token provider alias for the first hub")
            ASPEC.compile_time_assert(\{{ provider_aliases.includes?({"second_token_provider", "mercure_hub_second_jwt_provider"}) }}, "Expected a named token provider alias for the second hub")
          end
        end
      CR
    end
  end
end
