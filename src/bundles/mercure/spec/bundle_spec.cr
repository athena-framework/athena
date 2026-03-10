require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "./spec_helper.cr"

    @[ADI::Register(public: true)]
    class MercureConsumer
      def initialize(
        @hub : AMC::Hub::Interface,
        @authorization : ABM::Authorization,
        @discovery : ABM::Discovery,
      ); end
    end

    #{code}
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line
    require "./spec_helper.cr"

    @[ADI::Register(public: true)]
    class MercureConsumer
      def initialize(
        @hub : AMC::Hub::Interface,
        @authorization : ABM::Authorization,
        @discovery : ABM::Discovery,
      ); end
    end

    #{code}
  CR
end

describe ABM, tags: "compiled" do
  it "registers services for a hub with a jwt secret" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url: "https://hub.example.com/.well-known/mercure",
              jwt: {
                secret:    "looooooooooooongenoughtestsecret",
                publish:   ["*"],
                subscribe: ["https://example.com/books/{id}"],
              },
            },
          },
        },
      })

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH

            # Hub service
            hub = sh["mercure_hub_default"]
            raise "missing hub" unless hub
            raise "wrong class: #{hub["class"]}" unless hub["class"].resolve == Athena::Mercure::Hub

            params = hub["parameters"]
            raise "wrong url" unless params["url"]["value"] == "https://hub.example.com/.well-known/mercure"

            # Token factory should be set
            raise "token_factory should not be nil" if params["token_factory"]["value"] == nil

            # JWT factory service
            factory = sh["mercure_hub_default_jwt_factory"]
            raise "missing factory" unless factory
            raise "wrong factory class: #{factory["class"]}" unless factory["class"].resolve == Athena::Mercure::TokenFactory::JWT

            # Token provider service (factory-based)
            provider = sh["mercure_hub_default_jwt_provider"]
            raise "missing provider" unless provider
            raise "wrong provider class: #{provider["class"]}" unless provider["class"].resolve == Athena::Mercure::TokenProvider::Factory

            # Hub registry
            raise "missing registry" unless sh["mercure_hub_registry"]
            raise "wrong registry class" unless sh["mercure_hub_registry"]["class"].resolve == Athena::Mercure::Hub::Registry

            # Authorization
            raise "missing auth" unless sh["mercure_authorization"]
            raise "wrong auth class" unless sh["mercure_authorization"]["class"].resolve == Athena::MercureBundle::Authorization

            # Discovery
            raise "missing discovery" unless sh["mercure_discovery"]
            raise "wrong discovery class" unless sh["mercure_discovery"]["class"].resolve == Athena::MercureBundle::Discovery
          %}
        end
      end
    CR
  end

  it "registers services for a hub with a static jwt value" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url: "https://hub.example.com/.well-known/mercure",
              jwt: {
                value: "eyJhbGciOiJIUzI1NiJ9.static-token",
              },
            },
          },
        },
      })

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH

            # Hub service
            hub = sh["mercure_hub_default"]
            raise "missing hub" unless hub

            params = hub["parameters"]

            # Token factory should be nil for static token
            raise "token_factory should be nil: #{params["token_factory"]["value"]}" unless params["token_factory"]["value"] == nil.id

            # Static token provider
            provider = sh["mercure_hub_default_jwt_provider"]
            raise "missing provider" unless provider
            raise "wrong provider class: #{provider["class"]}" unless provider["class"].resolve == Athena::Mercure::TokenProvider::Static
          %}
        end
      end
    CR
  end

  it "uses the first hub as default when default_hub is not set" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            my_hub: {
              url: "https://hub.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
          },
        },
      })

      macro finished
        macro finished
          \{%
            registry = ADI::ServiceContainer::SERVICE_HASH["mercure_hub_registry"]
            default_hub = registry["parameters"]["default_hub"]["value"]
            raise "wrong default hub: #{default_hub}" unless default_hub.stringify =~ /mercure_hub_my_hub/
          %}
        end
      end
    CR
  end

  it "respects explicit default_hub setting" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            first: {
              url: "https://first.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
            second: {
              url: "https://second.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
          },
          default_hub: "second",
        },
      })

      macro finished
        macro finished
          \{%
            registry = ADI::ServiceContainer::SERVICE_HASH["mercure_hub_registry"]
            default_hub = registry["parameters"]["default_hub"]["value"]
            raise "wrong default hub: #{default_hub}" unless default_hub.stringify =~ /mercure_hub_second/
          %}
        end
      end
    CR
  end

  it "retains named aliases for all hubs in a multi-hub configuration" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            first: {
              url: "https://first.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
            second: {
              url: "https://second.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
          },
        },
      })

      macro finished
        macro finished
          \{%
            aliases = ADI::ServiceContainer::ALIASES[Athena::Mercure::Hub::Interface]

            # Named aliases for both hubs should be present, plus the unnamed default
            first_alias = aliases.find { |a| a["name"] && a["name"].id == "first" }
            raise "missing named alias for 'first' hub" unless first_alias
            raise "wrong id for 'first': #{first_alias["id"]}" unless first_alias["id"].stringify =~ /mercure_hub_first/

            second_alias = aliases.find { |a| a["name"] && a["name"].id == "second" }
            raise "missing named alias for 'second' hub" unless second_alias
            raise "wrong id for 'second': #{second_alias["id"]}" unless second_alias["id"].stringify =~ /mercure_hub_second/

            default_alias = aliases.find { |a| a["name"] == nil }
            raise "missing unnamed default alias" unless default_alias
            raise "default should be first hub: #{default_alias["id"]}" unless default_alias["id"].stringify =~ /mercure_hub_first/
          %}
        end
      end
    CR
  end

  it "passes cookie_lifetime from configuration" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url: "https://hub.example.com/.well-known/mercure",
              jwt: {
                secret: "looooooooooooongenoughtestsecret",
              },
            },
          },
          default_cookie_lifetime: 2.hours,
        },
      })

      macro finished
        macro finished
          \{%
            auth = ADI::ServiceContainer::SERVICE_HASH["mercure_authorization"]
            lifetime = auth["parameters"]["cookie_lifetime"]["value"]
            raise "wrong lifetime: #{lifetime}" unless lifetime.stringify == "2.hours"
          %}
        end
      end
    CR
  end
end
