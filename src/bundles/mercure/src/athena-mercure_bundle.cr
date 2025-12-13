require "athena-dependency_injection"
require "athena-http_kernel"
require "athena-mercure"

require "./authorization"
require "./discovery"

require "./listeners/*"

# Convenience alias to make referencing `Athena::MercureBundle` types easier.
alias ABM = Athena::MercureBundle

# The `Athena::MercureBundle` integrates the `Athena::Mercure` component into the Athena framework.
@[ADI::Bundle("mercure")]
struct Athena::MercureBundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  # Represents the possible properties used to configure and customize the Mercure integration.
  # See the [Getting Started](/getting_started/configuration) docs for more information on how the bundle system works in Athena.
  #
  # A full example showing all properties is as follows:
  #
  # ```
  # ADI.configure({
  #   mercure: {
  #     hubs: {
  #       default: {
  #         url:        "https://internal-hub/.well-known/mercure",
  #         public_url: "https://hub.example.com/.well-known/mercure",
  #         jwt:        {
  #           # Provide *secret* to generate JWTs dynamically via a token factory...
  #           secret:     "my-jwt-secret",
  #           publish:    ["*"],
  #           subscribe:  ["https://example.com/books/{id}"],
  #           algorithm:  :hs256,
  #           passphrase: "",
  #
  #           # ...or provide *value* to use a static JWT token directly.
  #           # value: "eyJhbGciOiJIUzI1NiJ9...",
  #         },
  #       },
  #     },
  #     default_hub:             "default",
  #     default_cookie_lifetime: 1.hour,
  #   },
  # })
  # ```
  module Schema
    include ADI::Extension::Schema

    # JWT configuration for authenticating with a Mercure hub.
    # Provide either *secret* to generate tokens dynamically, or *value* to use a static token.
    #
    # ---
    # >>secret: The secret key used to sign JWTs.
    # Required when generating tokens dynamically via a `AMC::TokenFactory::JWT` (i.e. when *value* is not set).
    # Should be set via ENV var.
    # >>publish: Topic selectors that the generated JWT grants publish access to. Included in the JWT's `mercure.publish` claim.
    # >>subscribe: Topic selectors that the generated JWT grants subscribe access to. Included in the JWT's `mercure.subscribe` claim.
    # >>algorithm: The signing algorithm used to encode the JWT.
    # >>passphrase: Passphrase for the secret key, if the algorithm requires one (e.g. RSA).
    # >>value: A pre-built static JWT token string provided via `AMC::TokenProvider::Static`. When set, the token is used as-is and *secret*, *algorithm*, and *passphrase* are ignored.
    # ---
    object_schema JWT,
      secret : String? = nil,
      publish : Array(String) = [] of String,
      subscribe : Array(String) = [] of String,
      algorithm : ::JWT::Algorithm = :hs256,
      passphrase : String = "",
      value : String? = nil

    # Named Mercure hub definitions. Each hub requires a *url* and *jwt* configuration.
    #
    # ---
    # >>url: The internal URL used by the server to publish updates to this hub.
    # Should be set via ENV var.
    # >>public_url: The public URL exposed to clients via the `Link` header for hub discovery.
    # Falls back to *url* if not set. Useful when the internal hub URL differs from the one clients should connect to.
    # Should be set via ENV var.
    # ---
    map_of hubs,
      url : String,
      public_url : String? = nil,
      jwt : JWT

    # The name of the hub to use when none is specified. Defaults to the first defined hub if not explicitly set.
    property default_hub : String? = nil

    # Default lifetime for authorization cookies set via `ABM::Authorization`.
    property default_cookie_lifetime : Time::Span = 1.hour
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            cfg = CONFIG["mercure"]
            parameters = CONFIG["parameters"]

            default_hub_id = nil
            default_hub_name = nil
            hubs = {} of Nil => Nil

            hub_aliases = [] of Nil
            token_factory_aliases = [] of Nil
            token_provider_aliases = [] of Nil

            cfg["hubs"].to_a.reject { |(name, _)| name.stringify == "__nil" }.each do |(name, hub)|
              token_provider = nil
              token_factory = nil

              jwt = hub["jwt"]

              if value = jwt["value"]
                SERVICE_HASH[token_provider = "mercure_hub_#{name}_jwt_provider"] = {
                  class:      Athena::Mercure::TokenProvider::Static,
                  parameters: {
                    token: {value: value},
                  },
                }
              else
                # TODO: Maybe support providing the factory/provider service ID?

                # TODO: Service is already lazy so no need for dedicated lazy service?
                SERVICE_HASH[token_factory = "mercure_hub_#{name}_jwt_factory"] = {
                  class:      Athena::Mercure::TokenFactory::JWT,
                  tags:       ["mercure.jwt.factory"],
                  parameters: {
                    jwt_secret: {value: jwt["secret"]},
                    algorithm:  {value: jwt["algorithm"]},
                    # jwt_lifetime: {value: nil},
                    passphrase: {value: jwt["passphrase"]},
                  },
                }

                SERVICE_HASH[token_provider = "mercure_hub_#{name}_jwt_provider"] = {
                  class:      Athena::Mercure::TokenProvider::Factory,
                  tags:       ["mercure.jwt.provider"],
                  parameters: {
                    factory:   {value: token_factory.id},
                    subscribe: {value: jwt["subscribe"]},
                    publish:   {value: jwt["publish"]},
                  },
                }

                token_factory_aliases << {id: token_factory, public: false, name: name}
                token_factory_aliases << {id: token_factory, public: false, name: "#{name}_factory"}
                token_factory_aliases << {id: token_factory, public: false, name: "#{name}_token_factory"}
              end

              if token_provider
                token_provider_aliases << {id: token_provider, public: false, name: name}
                token_provider_aliases << {id: token_provider, public: false, name: "#{name}_provider"}
                token_provider_aliases << {id: token_provider, public: false, name: "#{name}_token_provider"}
              end

              hub_id = "mercure_hub_#{name}"
              publisher_id = "mercure_hub_#{name}_publisher"
              hubs[name.stringify] = hub_id.id

              if cfg["default_hub"] == name || default_hub_id == nil
                default_hub_name = name
                default_hub_id = hub_id
              end

              SERVICE_HASH[hub_id] = {
                class:      Athena::Mercure::Hub,
                tags:       ["mercure.hub"],
                parameters: {
                  url:            {value: hub["url"]},
                  token_provider: {value: token_provider.id},
                  token_factory:  {value: token_factory ? token_factory.id : nil},
                  public_url:     {value: hub["public_url"]},
                  # http_client
                },
              }

              hub_aliases << {id: hub_id, public: false, name: name}
              hub_aliases << {id: hub_id, public: false, name: "#{name}_hub"}
            end

            # Unnamed alias resolves to the default hub
            hub_aliases << {id: default_hub_id, public: false}

            ALIASES[Athena::Mercure::Hub::Interface] = hub_aliases
            ALIASES[Athena::Mercure::TokenFactory::Interface] = token_factory_aliases unless token_factory_aliases.empty?
            ALIASES[Athena::Mercure::TokenProvider::Interface] = token_provider_aliases unless token_provider_aliases.empty?

            SERVICE_HASH[hub_registry_id = "mercure_hub_registry"] = {
              class:      Athena::Mercure::Hub::Registry,
              parameters: {
                default_hub: {value: default_hub_id.id},
                hubs:        {value: "#{hubs} of String => Athena::Mercure::Hub::Interface".id},
              },
            }

            SERVICE_HASH["mercure_authorization"] = {
              class:      ABM::Authorization,
              parameters: {
                hub_registry:    {value: hub_registry_id.id},
                cookie_lifetime: {value: cfg["default_cookie_lifetime"]},
              },
            }

            SERVICE_HASH["mercure_discovery"] = {
              class:      ABM::Discovery,
              parameters: {
                hub_registry: {value: hub_registry_id.id},
              },
            }
          %}
        {% end %}
      end
    end
  end
end

ADI.register_bundle Athena::MercureBundle
