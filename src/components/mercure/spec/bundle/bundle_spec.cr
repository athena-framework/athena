require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "./spec_helper.cr"

    @[ADI::Register(public: true)]
    class MercureConsumer
      def initialize(
        @hub : AMC::Hub::Interface,
        @authorization : AMC::Bundle::Authorization,
        @discovery : AMC::Bundle::Discovery,
      ); end
    end
  CR
end

describe AMC::Bundle, tags: "compiled" do
  it "registers services for a hub with a jwt secret" do
    assert_compiles <<-'CR'
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url: "https://hub.example.com/.well-known/mercure",
              jwt: {
                secret:    "looooooooooooongenoughtestsecret",
                claims:    {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
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
          ASPEC.compile_time_assert(\{{ sh["mercure_authorization"]["class"].resolve == Athena::Mercure::Bundle::Authorization }}, "Expected auth class to be Athena::Mercure::Bundle::Authorization")
          # Discovery
          ASPEC.compile_time_assert(\{{ sh["mercure_discovery"]["class"].resolve == Athena::Mercure::Bundle::Discovery }}, "Expected discovery class to be Athena::Mercure::Bundle::Discovery")
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
          ASPEC.compile_time_assert(\{{ params["token_factory"]["value"] == nil }}, "Expected token_factory to be nil")
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
                claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
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
          default_hub: "second",
        },
      })

      macro finished
        macro finished
          \{%
            default_hub = ADI::ServiceContainer::SERVICE_HASH["mercure_hub_registry"]["parameters"]["default_hub"]["value"]
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
                claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
              },
            },
          },
          default_cookie_lifetime: 2.hours,
        },
      })

      macro finished
        macro finished
          \{%
            lifetime = ADI::ServiceContainer::SERVICE_HASH["mercure_authorization"]["parameters"]["cookie_lifetime"]["value"]
          %}
          ASPEC.compile_time_assert(\{{ lifetime.stringify == "2.hours" }}, "Expected cookie_lifetime to be 2.hours")
        end
      end
    CR
  end

  it "registers the listeners with the framework's event dispatcher" do
    ASPEC::Methods.assert_compiles <<-'CR', preamble: %(require "athena"\nrequire "./spec_helper.cr")
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
            listener_ids = ADI::ServiceContainer::SERVICE_HASH["event_dispatcher"]["calls"].map { |(_, args)| args[0].stringify }
          %}
          ASPEC.compile_time_assert(\{{ listener_ids.includes? "mercure_add_link_header_listener" }}, "Expected the add link header listener to be registered")
          ASPEC.compile_time_assert(\{{ listener_ids.includes? "mercure_set_cookie_listener" }}, "Expected the set cookie listener to be registered")
        end
      end
    CR
  end

  describe "protocol 1.0" do
    it "generates RFC 9068 access tokens for the hub" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:        "https://internal/.well-known/mercure",
                public_url: "https://hub.example.com/.well-known/mercure",
                jwt:        {
                  secret:    "looooooooooooongenoughtestsecret",
                  claims:    {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                  publish:   ["*"],
                  subscribe: ["https://example.com/books/{id}"],
                },
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class HubConsumer
          getter hub : AMC::Hub::Interface

          def initialize(@hub : AMC::Hub::Interface); end
        end

        hub = ADI.container.hub_consumer.hub

        raise "Expected the hub to use the protocol 1.0" unless hub.protocol_version.v1?
        raise "Expected the secure cookie name" unless hub.cookie_name == "__Secure-mercure_access_token"

        publisher_payload, publisher_header = JWT.decode hub.token_provider.not_nil!.jwt, "looooooooooooongenoughtestsecret", :hs256

        raise "Expected an at+jwt token" unless publisher_header["typ"] == "at+jwt"
        raise "Expected the configured claims" unless publisher_payload["iss"] == "https://example.com" && publisher_payload["sub"] == "urn:app" && publisher_payload["client_id"] == "https://example.com"
        raise "Expected the publisher token to be for both hub URLs" unless publisher_payload["aud"] == JSON.parse %(["https://internal/.well-known/mercure", "https://hub.example.com/.well-known/mercure"])
        raise "Expected the publisher grants" unless publisher_payload["authorization_details"].as_a.map { |detail| {detail["actions"], detail["topics"]} } == [
                                                       {JSON.parse(%(["publish"])), JSON.parse(%([{"match": "*"}]))},
                                                       {JSON.parse(%(["subscribe"])), JSON.parse(%([{"match": "https://example.com/books/{id}"}]))},
                                                     ]

        subscriber_payload, _ = JWT.decode hub.token_factory.not_nil!.create(AMC::Grant.from("https://example.com/books/1")), "looooooooooooongenoughtestsecret", :hs256

        raise "Expected the subscriber token to be for the public hub URL" unless subscriber_payload["aud"] == "https://hub.example.com/.well-known/mercure"
        raise "Expected the configured claims" unless subscriber_payload["iss"] == "https://example.com"
      CR
    end

    it "allows overriding the audience" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url: "https://hub.example.com/.well-known/mercure",
                jwt: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com", "aud" => "custom", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class HubConsumer
          getter hub : AMC::Hub::Interface

          def initialize(@hub : AMC::Hub::Interface); end
        end

        hub = ADI.container.hub_consumer.hub

        publisher_payload, _ = JWT.decode hub.token_provider.not_nil!.jwt, "looooooooooooongenoughtestsecret", :hs256
        subscriber_payload, _ = JWT.decode hub.token_factory.not_nil!.create, "looooooooooooongenoughtestsecret", :hs256

        raise "Expected the configured publisher audience" unless publisher_payload["aud"] == "custom"
        raise "Expected the configured subscriber audience" unless subscriber_payload["aud"] == "custom"
      CR
    end

    it "signs the publisher and subscriber tokens with their own keys" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:       "https://hub.example.com/.well-known/mercure",
                publisher: {
                  secret: "publisherpublisherpublisherpublisher",
                  topics: ["*"],
                  claims: {"iss" => "https://example.com", "sub" => "urn:publisher", "client_id" => "https://example.com"},
                },
                subscriber: {
                  secret: "subscribersubscribersubscribersubscriber",
                  claims: {"iss" => "https://example.com", "sub" => "urn:subscriber", "client_id" => "https://example.com"},
                },
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class HubConsumer
          getter hub : AMC::Hub::Interface

          def initialize(@hub : AMC::Hub::Interface); end
        end

        hub = ADI.container.hub_consumer.hub

        publisher_payload, _ = JWT.decode hub.token_provider.not_nil!.jwt, "publisherpublisherpublisherpublisher", :hs256
        subscriber_payload, _ = JWT.decode hub.token_factory.not_nil!.create, "subscribersubscribersubscribersubscriber", :hs256

        raise "Expected the publisher claims" unless publisher_payload["sub"] == "urn:publisher"
        raise "Expected the publisher grants" unless publisher_payload["authorization_details"].as_a.map(&.["actions"]) == [JSON.parse(%(["publish"]))]
        raise "Expected the subscriber claims" unless subscriber_payload["sub"] == "urn:subscriber"
      CR
    end

    it "uses the configured token provider and factory services" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        @[ADI::Register(name: "app_token_provider")]
        class AppTokenProvider
          include AMC::TokenProvider::Interface

          def jwt : String
            "APP_JWT"
          end
        end

        @[ADI::Register(name: "app_token_factory")]
        class AppTokenFactory
          include AMC::TokenFactory::Interface

          def create(grants : Array(AMC::Grant) = [] of AMC::Grant, additional_claims : Hash? = nil) : String
            "#{grants.size} #{additional_claims}"
          end
        end

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:        "https://hub.example.com/.well-known/mercure",
                publisher:  {provider: "app_token_provider"},
                subscriber: {factory: "app_token_factory"},
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class HubConsumer
          getter hub : AMC::Hub::Interface
          getter default_token_provider : AMC::TokenProvider::Interface

          def initialize(@hub : AMC::Hub::Interface, @default_token_provider : AMC::TokenProvider::Interface); end
        end

        consumer = ADI.container.hub_consumer

        raise "Expected the configured token provider" unless consumer.hub.token_provider.try(&.jwt) == "APP_JWT"
        raise "Expected the token provider alias" unless consumer.default_token_provider.jwt == "APP_JWT"
        raise "Expected the configured token factory, with the default audience" unless consumer.hub.token_factory.try(&.create(AMC::Grant.from("a"))) == %(1 {"aud" => "https://hub.example.com/.well-known/mercure"})
      CR
    end

    it "wires the configured token provider and factory services" do
      assert_compiles <<-'CR'
        @[ADI::Register(name: "app_token_provider")]
        class AppTokenProvider
          include AMC::TokenProvider::Interface

          def jwt : String
            "APP_JWT"
          end
        end

        @[ADI::Register(name: "app_token_factory")]
        class AppTokenFactory
          include AMC::TokenFactory::Interface

          def create(grants : Array(AMC::Grant) = [] of AMC::Grant, additional_claims : Hash? = nil) : String
            "APP_JWT"
          end
        end

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url: "https://hub.example.com/.well-known/mercure",
                jwt: {provider: "app_token_provider"},
              },
              split: {
                url:        "https://hub.example.com/.well-known/mercure",
                publisher:  {provider: "app_token_provider"},
                subscriber: {factory: "app_token_factory"},
              },
              legacy: {
                url:              "https://hub.example.com/.well-known/mercure",
                protocol_version: "0.x",
                jwt:              {factory: "app_token_factory"},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              provider_aliases = ADI::ServiceContainer::ALIASES[Athena::Mercure::TokenProvider::Interface].map { |a| {a["name"], a["id"]} }
            %}
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default"]["parameters"]["token_provider"]["value"].stringify == "app_token_provider" }}, "Expected the default hub to use the configured token provider")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default"]["parameters"]["token_factory"]["value"] == nil }}, "Expected the default hub to not have a token factory")
            ASPEC.compile_time_assert(\{{ provider_aliases.includes?({"default_token_provider", "app_token_provider"}) }}, "Expected a named token provider alias for the configured token provider")

            ASPEC.compile_time_assert(\{{ sh["mercure_hub_split"]["parameters"]["token_provider"]["value"].stringify == "app_token_provider" }}, "Expected the split hub to use the configured token provider")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_split"]["parameters"]["token_factory"]["value"].stringify == "mercure_hub_split_subscriber_jwt_factory_default_claims" }}, "Expected the split hub to use the configured token factory with default claims")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_split_subscriber_jwt_factory_default_claims"]["parameters"]["decorated"]["value"].stringify == "app_token_factory" }}, "Expected the default claims to decorate the configured token factory")

            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy"]["parameters"]["token_factory"]["value"].stringify == "app_token_factory" }}, "Expected the legacy hub to use the configured token factory as is")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy_jwt_provider"]["parameters"]["factory"]["value"].stringify == "app_token_factory" }}, "Expected the legacy hub to publish with the configured token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy_jwt_provider"]["parameters"]["additional_claims"]["value"].stringify == "{} of String => String | Array(String)" }}, "Expected the legacy publisher token to not have an audience")
          end
        end
      CR
    end

    it "registers a token factory per signing key" do
      assert_compiles <<-'CR'
        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:        "https://internal/.well-known/mercure",
                public_url: "https://hub.example.com/.well-known/mercure",
                publisher:  {
                  secret: "publisherpublisherpublisherpublisher",
                  topics: ["*"],
                  claims: {"iss" => "https://example.com", "sub" => "urn:publisher", "client_id" => "https://example.com"},
                },
                subscriber: {
                  secret: "subscribersubscribersubscribersubscriber",
                  claims: {"iss" => "https://example.com", "sub" => "urn:subscriber", "client_id" => "https://example.com"},
                },
              },
              legacy: {
                url:              "https://hub.example.com/.well-known/mercure",
                protocol_version: "0.x",
                jwt:              {secret: "looooooooooooongenoughtestsecret"},
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
            %}
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_publisher_jwt_factory"]["parameters"]["jwt_secret"]["value"] == "publisherpublisherpublisherpublisher" }}, "Expected a publisher token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_subscriber_jwt_factory"]["parameters"]["jwt_secret"]["value"] == "subscribersubscribersubscribersubscriber" }}, "Expected a subscriber token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_factory"] == nil }}, "Expected no shared token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default"]["parameters"]["token_factory"]["value"].stringify == "mercure_hub_default_subscriber_jwt_factory_default_claims" }}, "Expected the hub to use the subscriber token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_provider"]["parameters"]["factory"]["value"].stringify == "mercure_hub_default_publisher_jwt_factory_default_claims" }}, "Expected the hub to publish with the publisher token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_provider"]["parameters"]["additional_claims"]["value"].stringify.includes? %(["https://internal/.well-known/mercure", "https://hub.example.com/.well-known/mercure"]) }}, "Expected the publisher token to be for both hub URLs")

            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy_jwt_factory"]["parameters"]["protocol_version"]["value"].stringify == "Athena::Mercure::ProtocolVersion::Legacy" }}, "Expected a protocol 0.x token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy_jwt_factory_default_claims"] == nil }}, "Expected no default claims for the protocol 0.x token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy"]["parameters"]["protocol_version"]["value"].stringify == "Athena::Mercure::ProtocolVersion::Legacy" }}, "Expected a protocol 0.x hub")
          end
        end
      CR
    end

    it "shares the token factory of a publisher and subscriber with the same signing options" do
      assert_compiles <<-'CR'
        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:       "https://hub.example.com/.well-known/mercure",
                publisher: {
                  secret: "looooooooooooongenoughtestsecret",
                  topics: ["*"],
                  claims: {"iss" => "https://example.com", "sub" => "urn:app", "client_id" => "https://example.com"},
                },
                subscriber: {
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
              sh = ADI::ServiceContainer::SERVICE_HASH
            %}
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_factory"]["class"].resolve == Athena::Mercure::TokenFactory::JWT }}, "Expected a shared token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_publisher_jwt_factory"] == nil }}, "Expected no publisher token factory")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_subscriber_jwt_factory"] == nil }}, "Expected no subscriber token factory")
          end
        end
      CR
    end

    it "defaults the cookie name of a hub in debug mode" do
      assert_compiles <<-'CR'
        ADI.configure({
          parameters: {
            "framework.debug": true,
          },
          mercure: {
            hubs: {
              default: {
                url: "https://hub.example.com/.well-known/mercure",
                jwt: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
              },
              explicit: {
                url:         "https://hub.example.com/.well-known/mercure",
                jwt:         {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
                cookie_name: "custom",
              },
              legacy: {
                url:              "https://hub.example.com/.well-known/mercure",
                jwt:              {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
                protocol_version: "0.x",
              },
            },
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
            %}
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default"]["parameters"]["cookie_name"]["value"] == "mercure_access_token" }}, "Expected the debug cookie name")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_explicit"]["parameters"]["cookie_name"]["value"] == "custom" }}, "Expected the configured cookie name")
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_legacy"]["parameters"]["cookie_name"]["value"] == nil }}, "Expected the protocol 0.x default cookie name")
          end
        end
      CR
    end

    it "does not default the cookie name of a hub outside of debug mode" do
      assert_compiles <<-'CR'
        ADI.configure({
          parameters: {
            "framework.debug": false,
          },
          mercure: {
            hubs: {
              default: {
                url: "https://hub.example.com/.well-known/mercure",
                jwt: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
              },
            },
          },
        })

        macro finished
          macro finished
            ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["mercure_hub_default"]["parameters"]["cookie_name"]["value"] == nil }}, "Expected the protocol 1.0 default cookie name")
          end
        end
      CR
    end

    it "defaults the cookie name of a hub in the framework's debug mode" do
      ASPEC::Methods.assert_compiles <<-'CR', preamble: %(require "../../src/bundle"\nrequire "athena"\nrequire "athena-spec")
        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url: "https://hub.example.com/.well-known/mercure",
                jwt: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
              },
            },
          },
        })

        macro finished
          macro finished
            ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["mercure_hub_default"]["parameters"]["cookie_name"]["value"] == "mercure_access_token" }}, "Expected the debug cookie name")
          end
        end
      CR
    end

    it "errors if a token factory is missing a required claim" do
      ASPEC::Methods.assert_compile_time_error "The 'mercure.hubs.default.subscriber.claims' option must define the 'sub', 'client_id' claim(s), as they are required by RFC 9068 access tokens when 'protocol_version' is '1.0' and 'subscriber.secret' is used.", <<-'CR', preamble: %(require "./spec_helper.cr")
        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:        "https://hub.example.com/.well-known/mercure",
                publisher:  {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
                subscriber: {
                  secret: "looooooooooooongenoughtestsecret",
                  claims: {"iss" => "https://example.com"},
                },
              },
            },
          },
        })
      CR
    end
  end

  describe "protocol 0.x" do
    it "generates tokens with the mercure claim" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "jwt"
        require "../../src/bundle"

        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url:              "https://hub.example.com/.well-known/mercure",
                protocol_version: "0.x",
                jwt:              {
                  secret:  "looooooooooooongenoughtestsecret",
                  publish: ["*"],
                },
              },
            },
          },
        })

        @[ADI::Register(public: true)]
        class HubConsumer
          getter hub : AMC::Hub::Interface

          def initialize(@hub : AMC::Hub::Interface); end
        end

        hub = ADI.container.hub_consumer.hub

        raise "Expected the hub to use the protocol 0.x" unless hub.protocol_version.legacy?
        raise "Expected the legacy cookie name" unless hub.cookie_name == "mercureAuthorization"

        publisher_payload, publisher_header = JWT.decode hub.token_provider.not_nil!.jwt, "looooooooooooongenoughtestsecret", :hs256

        raise "Expected a JWT token" unless publisher_header["typ"] == "JWT"
        raise "Expected the mercure claim" unless publisher_payload["mercure"] == JSON.parse %({"publish": ["*"], "subscribe": []})
        raise "Expected no audience" unless publisher_payload["aud"]?.nil?

        subscriber_payload, _ = JWT.decode hub.token_factory.not_nil!.create(AMC::Grant.from("https://example.com/books/1")), "looooooooooooongenoughtestsecret", :hs256

        raise "Expected the subscriber mercure claim" unless subscriber_payload["mercure"] == JSON.parse %({"subscribe": ["https://example.com/books/1"]})
      CR
    end
  end

  it "errors on an unknown protocol version" do
    ASPEC::Methods.assert_compile_time_error "Unknown Mercure protocol version '2.0' for hub 'default'. Expected '1.0' or '0.x'.", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url:              "https://hub.example.com/.well-known/mercure",
              jwt:              {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
              protocol_version: "2.0",
            },
          },
        },
      })
    CR
  end

  it "errors if the default hub is not defined" do
    ASPEC::Methods.assert_compile_time_error "The 'mercure.default_hub' option refers to the 'missing' hub, which is not defined. Defined hubs: 'first', 'second'.", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            first: {
              url: "https://first.example.com/.well-known/mercure",
              jwt: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
            },
            second: {
              url: "https://second.example.com/.well-known/mercure",
              jwt: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
            },
          },
          default_hub: "missing",
        },
      })
    CR
  end

  it "errors if a hub uses both jwt and publisher" do
    ASPEC::Methods.assert_compile_time_error "Mercure hub 'default' cannot use both 'jwt' and 'publisher'/'subscriber'.", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url:       "https://hub.example.com/.well-known/mercure",
              jwt:       {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
              publisher: {value: "eyJhbGciOiJIUzI1NiJ9.static-token"},
            },
          },
        },
      })
    CR
  end

  it "errors if a hub has no publisher token" do
    ASPEC::Methods.assert_compile_time_error "Mercure hub 'default' must specify at least one of 'jwt' or 'publisher'.", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url:        "https://hub.example.com/.well-known/mercure",
              subscriber: {factory: "app_token_factory"},
            },
          },
        },
      })
    CR
  end

  it "errors if a hub uses both a static token and a token provider" do
    ASPEC::Methods.assert_compile_time_error "Mercure hub 'default' cannot use both 'publisher.value' and 'publisher.provider'.", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url:       "https://hub.example.com/.well-known/mercure",
              publisher: {value: "eyJhbGciOiJIUzI1NiJ9.static-token", provider: "app_token_provider"},
            },
          },
        },
      })
    CR
  end
end
