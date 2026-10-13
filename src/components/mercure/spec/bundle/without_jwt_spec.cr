require "./spec_helper"

private PREAMBLE = <<-'CR'
  require "../../src/bundle"
  require "athena-spec"
  CR

describe AMC::Bundle, tags: "compiled" do
  describe "without the jwt shard" do
    it "supports hubs with a static token, even when built with -Dwithout_openssl" do
      ASPEC::Methods.assert_compiles <<-'CR', preamble: PREAMBLE, flags: ["without_openssl"]
        ADI.configure({
          mercure: {
            hubs: {
              default: {
                url: "http://mercure/.well-known/mercure",
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
            %}
            ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_provider"]["class"].resolve == Athena::Mercure::TokenProvider::Static }}, "Expected provider class to be Athena::Mercure::TokenProvider::Static")
            ASPEC.compile_time_assert(\{{ parse_type("Athena::Mercure::TokenFactory::JWT").resolve? == nil }}, "Expected the JWT token factory to not be available")
          end
        end
      CR
    end

    it "errors if a hub generates tokens" do
      ASPEC::Methods.assert_compile_time_error %(Mercure hub 'default' generates JWTs, which requires the `jwt` shard. Add it to your `shard.yml` and `require "jwt"`, or use a static token via 'jwt.value'.), <<-'CR', preamble: PREAMBLE
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
          },
        })
      CR
    end
  end

  it "makes the JWT token factory available when the jwt shard is required afterwards" do
    ASPEC::Methods.assert_compiles <<-'CR', preamble: PREAMBLE
      require "jwt"

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
        },
      })

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["mercure_hub_default_jwt_factory"]["class"].resolve == Athena::Mercure::TokenFactory::JWT }}, "Expected factory class to be Athena::Mercure::TokenFactory::JWT")
        end
      end
    CR
  end

  it "errors on an unknown JWT algorithm" do
    ASPEC::Methods.assert_compile_time_error "Unknown JWT algorithm 'foo' for Mercure hub 'default'. Expected one of: none, hs256,", <<-'CR', preamble: %(require "./spec_helper.cr")
      ADI.configure({
        mercure: {
          hubs: {
            default: {
              url:  "https://hub.example.com/.well-known/mercure",
              jwt: {
                secret:    "looooooooooooongenoughtestsecret",
                algorithm: :foo,
              },
            },
          },
        },
      })
    CR
  end
end
