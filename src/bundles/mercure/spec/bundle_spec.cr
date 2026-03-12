require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line - 11 # Account for extra code before *code* is interpolated
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
            params = hub["parameters"]

            # JWT factory service
            factory = sh["mercure_hub_default_jwt_factory"]

            # Token provider service (factory-based)
            provider = sh["mercure_hub_default_jwt_provider"]
          %}
          ASPEC.compile_time_assert(\{{ hub["class"].resolve == Athena::Mercure::Hub }}, "Expected hub class to be Athena::Mercure::Hub")
          ASPEC.compile_time_assert(\{{ params["url"]["value"] == "https://hub.example.com/.well-known/mercure" }}, "Expected hub url to match configuration")
          # Token factory should be set
          ASPEC.compile_time_assert(\{{ params["token_factory"]["value"] != nil }}, "Expected token_factory to be set")
          ASPEC.compile_time_assert(\{{ factory["class"].resolve == Athena::Mercure::TokenFactory::JWT }}, "Expected factory class to be Athena::Mercure::TokenFactory::JWT")
          ASPEC.compile_time_assert(\{{ provider["class"].resolve == Athena::Mercure::TokenProvider::Factory }}, "Expected provider class to be Athena::Mercure::TokenProvider::Factory")
          # Hub registry
          ASPEC.compile_time_assert(\{{ sh["mercure_hub_registry"]["class"].resolve == Athena::Mercure::Hub::Registry }}, "Expected registry class to be Athena::Mercure::Hub::Registry")
          # Authorization
          ASPEC.compile_time_assert(\{{ sh["mercure_authorization"]["class"].resolve == Athena::MercureBundle::Authorization }}, "Expected auth class to be Athena::MercureBundle::Authorization")
          # Discovery
          ASPEC.compile_time_assert(\{{ sh["mercure_discovery"]["class"].resolve == Athena::MercureBundle::Discovery }}, "Expected discovery class to be Athena::MercureBundle::Discovery")
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

            hub = sh["mercure_hub_default"]
            params = hub["parameters"]

            # Static token provider
            provider = sh["mercure_hub_default_jwt_provider"]
          %}
          # Token factory should be nil for static token
          ASPEC.compile_time_assert(\{{ params["token_factory"]["value"] == nil.id }}, "Expected token_factory to be nil")
          ASPEC.compile_time_assert(\{{ provider["class"].resolve == Athena::Mercure::TokenProvider::Static }}, "Expected provider class to be Athena::Mercure::TokenProvider::Static")
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
            default_hub = ADI::ServiceContainer::SERVICE_HASH["mercure_hub_registry"]["parameters"]["default_hub"]["value"]
          %}
          ASPEC.compile_time_assert(\{{ default_hub.stringify =~ /mercure_hub_my_hub/ }}, "Expected default hub to be my_hub")
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
          %}
          ASPEC.compile_time_assert(\{{ default_hub.stringify =~ /mercure_hub_second/ }}, "Expected default hub to be second")
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
            first_alias = aliases.find { |a| a["name"].id == "first" }
            second_alias = aliases.find { |a| a["name"].id == "second" }
            default_alias = aliases.find { |a| a["name"] == nil }
          %}
          ASPEC.compile_time_assert(\{{ first_alias["id"].stringify =~ /mercure_hub_first/ }}, "Expected first alias id to match mercure_hub_first")
          ASPEC.compile_time_assert(\{{ second_alias["id"].stringify =~ /mercure_hub_second/ }}, "Expected second alias id to match mercure_hub_second")
          ASPEC.compile_time_assert(\{{ default_alias["id"].stringify =~ /mercure_hub_first/ }}, "Expected default alias to be first hub")
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
          %}
          ASPEC.compile_time_assert(\{{ lifetime.stringify == "2.hours" }}, "Expected cookie_lifetime to be 2.hours")
        end
      end
    CR
  end
end
