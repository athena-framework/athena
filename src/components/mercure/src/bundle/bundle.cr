# Integrates the Mercure component with the [dependency injection](/DependencyInjection/) and [HTTP kernel](/HTTPKernel/) components, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-mercure/bundle` to register the bundle, then configure at least one hub:
#
# ```
# require "athena"
# require "athena-mercure/bundle"
#
# ADI.configure({
#   mercure: {
#     hubs: {
#       default: {
#         url: ENV["MERCURE_URL"],
#         jwt: {
#           secret:    ENV["MERCURE_JWT_SECRET"],
#           publish:   ["*"],
#           subscribe: ["*"],
#           claims:    {
#             "iss"       => "https://example.com",
#             "sub"       => "urn:example:app",
#             "client_id" => "https://example.com",
#           },
#         },
#       },
#     },
#   },
# })
# ```
#
# See `Schema` for the full set of possible configuration options.
#
# Hubs speak the Mercure protocol 1.0 by default, whose [RFC 9068](https://datatracker.ietf.org/doc/html/rfc9068) access tokens require the `iss`, `sub`, and `client_id` claims.
# Set the hub's `protocol_version` to `"0.x"` to use a hub older than 1.0.
#
# NOTE: Hubs configured with a *secret* generate their JWTs via the optional `jwt` shard, see the [installation](/Mercure/#installation) instructions.
# Hubs with a static token, via `jwt: {value: "..."}`, do not need it, but `AMC::Bundle::Authorization` cookies are not available to them.
#
# If multiple hubs are configured, they may be injected using the hub name as a constructor parameter typed to `AMC::Hub::Interface`.
# For example `some_hub : AMC::Hub::Interface` assuming the key used in the `hubs` named tuple was `some_hub`.
#
# The bundle brings `AMC::Hub`, `AMC::Bundle::Authorization`, and `AMC::Bundle::Discovery` into the framework as injectable services, with event listeners that handle response headers and cookies automatically.
#
# ## Publishing
#
# Inject `AMC::Hub::Interface` to publish updates from a controller:
#
# ```
# @[ARTA::Route(path: "/broadcast")]
# class BroadcastController < ATH::Controller
#   def initialize(@hub : AMC::Hub::Interface); end
#
#   @[ARTA::Post("/")]
#   def broadcast : Nil
#     @hub.publish AMC::Update.new(
#       "https://example.com/books/1",
#       {status: "OutOfStock"}.to_json
#     )
#   end
# end
# ```
#
# ## Authorization
#
# Inject `AMC::Bundle::Authorization` to set the authorization cookie of a hub for [private updates](/Mercure/#authorization).
# The `AMC::Bundle::Listeners::SetCookie` listener automatically adds the cookie to the response — there is no need to modify the response directly:
#
# ```
# @[ARTA::Route(path: "/auth")]
# class AuthController < ATH::Controller
#   def initialize(@authorization : AMC::Bundle::Authorization); end
#
#   @[ARTA::Get("/subscribe")]
#   def subscribe(request : AHTTP::Request) : Nil
#     @authorization.set_cookie request, {"urlpattern" => ["https://example.com/books/:id"]}
#   end
# end
# ```
#
# See [Authorization](/Mercure/#authorization) in the Mercure component docs for more on private updates and cookie-based auth.
#
# ## Discovery
#
# Inject `AMC::Bundle::Discovery` to add the Mercure hub `Link` header to a response.
# The `AMC::Bundle::Listeners::AddLinkHeader` listener handles adding the header — there is no need to modify the response directly:
#
# ```
# @[ARTA::Route(path: "/books")]
# class BookController < ATH::Controller
#   def initialize(@discovery : AMC::Bundle::Discovery); end
#
#   @[ARTA::Get("/{id}")]
#   def show(request : AHTTP::Request, id : Int32) : {id: Int32, title: String}
#     @discovery.add_link request
#
#     {id: id, title: "Hello World!"}
#   end
# end
# ```
#
# The response will include a `Link: <https://hub.example.com/.well-known/mercure>; rel="mercure"` header.
# A client can then extract the hub URL to subscribe to updates for this resource:
#
# ```js
# fetch('/books/1')
#   .then(response => {
#     const hubUrl = response.headers.get('Link').match(/<([^>]+)>;\s+rel=(?:mercure|"[^"]*mercure[^"]*")/)[1];
#
#     const hub = new URL(hubUrl, window.origin);
#     hub.searchParams.append('match_urlpattern', 'https://example.com/books/:id');
#
#     const eventSource = new EventSource(hub);
#     eventSource.onmessage = event => console.log(event.data);
#   });
# ```
#
# See [Discovery](/Mercure/#discovery) in the Mercure component docs for more on the discovery protocol.
@[ADI::Bundle("mercure")]
struct Athena::Mercure::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [
    {Athena::Mercure::Bundle::CompilerPasses::ConfigureDebugCookieName, :before_optimization, 1027},
  ]

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
  #           subscribe:  ["https://example.com/books/1"],
  #           algorithm:  :hs256,
  #           passphrase: "",
  #           claims:     {
  #             "iss"       => "https://example.com",
  #             "sub"       => "urn:example:app",
  #             "client_id" => "https://example.com",
  #           },
  #
  #           # ...or provide *value* to use a static JWT token directly.
  #           # value: "eyJhbGciOiJIUzI1NiJ9...",
  #         },
  #         protocol_version: "1.0",
  #         cookie_name:      "__Secure-mercure_access_token",
  #       },
  #       separate_keys: {
  #         url:       "https://hub.example.com/.well-known/mercure",
  #         publisher: {
  #           secret: "my-publisher-jwt-secret",
  #           topics: ["*"],
  #           claims: {"iss" => "https://example.com", "sub" => "urn:example:app", "client_id" => "https://example.com"},
  #         },
  #         subscriber: {
  #           secret: "my-subscriber-jwt-secret",
  #           claims: {"iss" => "https://example.com", "sub" => "urn:example:app", "client_id" => "https://example.com"},
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

    # JWT configuration for authenticating with a Mercure hub, used both to publish updates and to create the subscriber tokens of `AMC::Bundle::Authorization`.
    # Provide one of *value* or *provider* to publish with a static token or your own provider, and/or one of *secret* or *factory* to generate tokens dynamically.
    # Generating tokens via *secret* requires the optional `jwt` shard, see the [installation](/Mercure/#installation) instructions.
    #
    # TODO: Support fetching the signing key from a JSON Web Key Set via `jwks_uri` and `key_id`, as an alternative to *secret*.
    # Configuring them is currently an error.
    #
    # ---
    # >>value: A pre-built static JWT token string provided via `AMC::TokenProvider::Static`. When set, the token is used as-is to publish updates.
    # >>provider: The ID of a service implementing `AMC::TokenProvider::Interface` that provides the token used to publish updates.
    # >>factory: The ID of a service implementing `AMC::TokenFactory::Interface` used to generate tokens, instead of *secret*.
    # >>secret: The secret key used to sign JWTs generated via `AMC::TokenFactory::JWT`.
    # Should be set via ENV var.
    # >>passphrase: Passphrase for the secret key, if the algorithm requires one (e.g. RSA).
    # >>algorithm: The signing algorithm used to encode the JWT, as the name of a [JWT::Algorithm](https://github.com/crystal-community/jwt#supported-algorithms) member, such as `:hs256` or `:rs256`.
    # >>claims: Additional claims of the generated JWTs.
    # Under the Mercure protocol 1.0, the `iss`, `sub`, and `client_id` claims are required when using *secret*, and `aud` defaults to the hub's *public_url*, or *url*.
    # >>publish: Topic selectors that the token used to publish updates is allowed to publish to.
    # >>subscribe: Topic selectors that the token used to publish updates is allowed to subscribe to.
    # ---
    object_schema JWT,
      value : String? = nil,
      provider : String? = nil,
      factory : String? = nil,
      secret : String? = nil,
      passphrase : String = "",
      algorithm : Symbol = :hs256,
      claims : Hash(String, String | Array(String)) = {} of String => String | Array(String),
      publish : Array(String) = [] of String,
      subscribe : Array(String) = [] of String

    # Configuration of the JWT used to publish updates to a Mercure hub.
    # Use with *subscriber* to sign the publisher and subscriber tokens with different keys, as an alternative to *jwt*.
    #
    # ---
    # >>value: A pre-built static JWT token string provided via `AMC::TokenProvider::Static`.
    # >>provider: The ID of a service implementing `AMC::TokenProvider::Interface` that provides the token.
    # >>factory: The ID of a service implementing `AMC::TokenFactory::Interface` used to generate the token, instead of *secret*.
    # >>topics: Topic selectors that the generated token is allowed to publish to.
    # >>secret: The secret key used to sign the token generated via `AMC::TokenFactory::JWT`.
    # Should be set via ENV var.
    # >>passphrase: Passphrase for the secret key, if the algorithm requires one (e.g. RSA).
    # >>algorithm: The signing algorithm used to encode the JWT, as the name of a [JWT::Algorithm](https://github.com/crystal-community/jwt#supported-algorithms) member, such as `:hs256` or `:rs256`.
    # >>claims: Additional claims of the generated token, see the *claims* of *jwt*.
    # ---
    object_schema Publisher,
      value : String? = nil,
      provider : String? = nil,
      factory : String? = nil,
      topics : Array(String) = [] of String,
      secret : String? = nil,
      passphrase : String = "",
      algorithm : Symbol = :hs256,
      claims : Hash(String, String | Array(String)) = {} of String => String | Array(String)

    # Configuration of the JWTs created for subscribers, such as via `AMC::Bundle::Authorization`.
    # Use with *publisher* to sign the publisher and subscriber tokens with different keys, as an alternative to *jwt*.
    #
    # ---
    # >>factory: The ID of a service implementing `AMC::TokenFactory::Interface` used to generate the tokens, instead of *secret*.
    # >>secret: The secret key used to sign the tokens generated via `AMC::TokenFactory::JWT`.
    # Should be set via ENV var.
    # >>passphrase: Passphrase for the secret key, if the algorithm requires one (e.g. RSA).
    # >>algorithm: The signing algorithm used to encode the JWTs, as the name of a [JWT::Algorithm](https://github.com/crystal-community/jwt#supported-algorithms) member, such as `:hs256` or `:rs256`.
    # >>claims: Additional claims of the generated tokens, see the *claims* of *jwt*.
    # ---
    object_schema Subscriber,
      factory : String? = nil,
      secret : String? = nil,
      passphrase : String = "",
      algorithm : Symbol = :hs256,
      claims : Hash(String, String | Array(String)) = {} of String => String | Array(String)

    # Named Mercure hub definitions. Each hub requires a *url*, and either a *jwt* or a *publisher* configuration.
    #
    # TODO: Support publishing the updates of a hub via a dedicated `HTTP::Client` service, via `http_client`.
    # Configuring it is currently an error.
    #
    # ---
    # >>url: The internal URL used by the server to publish updates to this hub.
    # Should be set via ENV var.
    # >>public_url: The public URL exposed to clients via the `Link` header for hub discovery.
    # Falls back to *url* if not set. Useful when the internal hub URL differs from the one clients should connect to.
    # Should be set via ENV var.
    # >>jwt: The JWT configuration used for both publishing and subscribing, see `JWT`.
    # >>publisher: The JWT configuration used for publishing, as an alternative to *jwt*, see `Publisher`.
    # >>subscriber: The JWT configuration used for subscribing, as an alternative to *jwt*, see `Subscriber`.
    # >>protocol_version: The version of the Mercure protocol this hub speaks, `"1.0"` or `"0.x"`.
    # Affects the default *cookie_name*, and the claims of the tokens generated via *secret*.
    # >>cookie_name: The name of the subscriber authorization cookie.
    # Defaults to `__Secure-mercure_access_token` under the Mercure protocol 1.0, or `mercure_access_token` if the `framework.debug` parameter is `true`, as browsers drop `__Secure-` cookies over plain HTTP.
    # Defaults to `mercureAuthorization` under the Mercure protocol 0.x.
    # ---
    map_of hubs,
      url : String,
      public_url : String? = nil,
      jwt : JWT = {value: nil},
      publisher : Publisher = {value: nil},
      subscriber : Subscriber = {factory: nil},
      protocol_version : String = "1.0",
      cookie_name : String? = nil

    # The name of the hub to use when none is specified. Defaults to the first defined hub if not explicitly set.
    property default_hub : String? = nil

    # Default lifetime for authorization cookies set via `AMC::Bundle::Authorization`.
    property default_cookie_lifetime : Time::Span = 1.hour
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            cfg = CONFIG["mercure"]

            default_hub_id = nil
            default_hub_name = nil
            hubs = {} of Nil => Nil

            hub_aliases = [] of Nil
            token_factory_aliases = [] of Nil
            token_provider_aliases = [] of Nil

            cfg["hubs"].to_a.reject { |(name, _)| name.stringify == "__nil" }.each do |(name, hub)|
              unless {"1.0", "0.x"}.includes? hub["protocol_version"]
                hub["protocol_version"].raise "Unknown Mercure protocol version '#{hub["protocol_version"].id}' for hub '#{name.id}'. Expected '1.0' or '0.x'."
              end

              v1 = "1.0" == hub["protocol_version"]

              jwt = hub["jwt"]
              publisher = hub["publisher"]
              subscriber = hub["subscriber"]

              # The object schemas always have a value, so they are considered configured if they define how to obtain a token.
              jwt_configured = jwt["value"] || jwt["provider"] || jwt["factory"] || jwt["secret"]
              publisher_configured = publisher["value"] || publisher["provider"] || publisher["factory"] || publisher["secret"]
              subscriber_configured = subscriber["factory"] || subscriber["secret"]

              if jwt_configured && (publisher_configured || subscriber_configured)
                name.raise "Mercure hub '#{name.id}' cannot use both 'jwt' and 'publisher'/'subscriber'."
              end

              if !jwt_configured && !publisher_configured
                name.raise "Mercure hub '#{name.id}' must specify at least one of 'jwt' or 'publisher'."
              end

              {"jwt" => jwt, "publisher" => publisher}.each do |path, signing|
                if signing["value"] && signing["provider"]
                  name.raise "Mercure hub '#{name.id}' cannot use both '#{path.id}.value' and '#{path.id}.provider'."
                end
              end

              # Each token factory to register, as `{id, signing options, config path}`.
              token_factory_definitions = [] of Nil

              token_factory = nil
              token_provider = nil

              # Updates are published with either a static token, the token of a provider service, or a token from a factory.
              static_token = nil
              provider_id = nil

              # As `{factory ID, publish topics, subscribe topics, signing options}`.
              publisher_factory = nil

              if jwt_configured
                if jwt["value"]
                  static_token = jwt["value"]
                elsif jwt["provider"]
                  provider_id = jwt["provider"]
                else
                  token_factory_definitions << {token_factory = "mercure_hub_#{name}_jwt_factory", jwt, "jwt"}
                  publisher_factory = {token_factory, jwt["publish"], jwt["subscribe"], jwt}
                end
              else
                signing_options = {"secret", "passphrase", "algorithm", "claims"}
                shared_factory = publisher_configured && subscriber_configured && !publisher["factory"] && !subscriber["factory"] && signing_options.all? { |o| publisher[o] == subscriber[o] }

                if subscriber_configured
                  token_factory_definitions << {token_factory = "mercure_hub_#{name}_#{shared_factory ? "".id : "subscriber_".id}jwt_factory", subscriber, "subscriber"}
                end

                if publisher["value"]
                  static_token = publisher["value"]
                elsif publisher["provider"]
                  provider_id = publisher["provider"]
                elsif publisher_configured
                  publisher_factory_id = shared_factory ? token_factory : "mercure_hub_#{name}_publisher_jwt_factory"
                  token_factory_definitions << {publisher_factory_id, publisher, "publisher"} unless shared_factory

                  publisher_factory = {publisher_factory_id, publisher["topics"], [] of Nil, publisher}
                end
              end

              # The ID of the service providing the tokens of each factory, such as the `DefaultClaims` service decorating it.
              decorated_factories = {} of Nil => Nil

              token_factory_definitions.each do |(factory_id, signing, path)|
                if user_factory = signing["factory"]
                  factory_service_id = user_factory
                else
                  unless @top_level.has_constant?("JWT")
                    name.raise "Mercure hub '#{name.id}' generates JWTs, which requires the `jwt` shard. Add it to your `shard.yml` and `require \"jwt\"`, or use a static token via '#{path.id}.value'."
                  end

                  algorithms = parse_type("::JWT::Algorithm").resolve.constants.map(&.stringify.downcase)

                  unless algorithms.includes? signing["algorithm"].id.stringify.downcase
                    signing["algorithm"].raise "Unknown JWT algorithm '#{signing["algorithm"].id}' for Mercure hub '#{name.id}'. Expected one of: #{algorithms.join(", ").id}."
                  end

                  if v1
                    missing_claims = {"iss", "sub", "client_id"}.reject { |claim| signing["claims"][claim] }

                    unless missing_claims.empty?
                      name.raise "The 'mercure.hubs.#{name.id}.#{path.id}.claims' option must define the '#{missing_claims.join("', '").id}' claim(s), as they are required by RFC 9068 access tokens when 'protocol_version' is '1.0' and '#{path.id}.secret' is used."
                    end
                  end

                  SERVICE_HASH[factory_id] = {
                    class:      Athena::Mercure::TokenFactory::JWT,
                    tags:       ["mercure.jwt.factory"],
                    parameters: {
                      jwt_secret:       {value: signing["secret"]},
                      algorithm:        {value: signing["algorithm"]},
                      passphrase:       {value: signing["passphrase"]},
                      protocol_version: {value: (v1 ? "Athena::Mercure::ProtocolVersion::V1" : "Athena::Mercure::ProtocolVersion::Legacy").id},
                    },
                  }

                  factory_service_id = factory_id
                end

                default_claims = {} of Nil => Nil

                signing["claims"].each { |k, v| default_claims[k] = v }

                # Under the Mercure protocol 1.0, a token's audience is the hub it is sent to.
                if v1 && !default_claims["aud"]
                  default_claims["aud"] = hub["public_url"] || hub["url"]
                end

                if default_claims.empty?
                  decorated_factories[factory_id] = factory_service_id
                else
                  SERVICE_HASH[decorated_id = "#{factory_id.id}_default_claims"] = {
                    class:      Athena::Mercure::TokenFactory::DefaultClaims,
                    parameters: {
                      decorated:      {value: "@#{factory_service_id.id}"},
                      default_claims: {value: "#{default_claims} of String => String | Array(String)".id},
                    },
                  }

                  decorated_factories[factory_id] = decorated_id
                end
              end

              if token_factory
                token_factory = decorated_factories[token_factory]
              end

              if static_token
                SERVICE_HASH[token_provider = "mercure_hub_#{name}_jwt_provider"] = {
                  class:      Athena::Mercure::TokenProvider::Static,
                  parameters: {
                    token: {value: static_token},
                  },
                }
              elsif provider_id
                token_provider = provider_id
              elsif publisher_factory
                publisher_factory_id, publish, subscribe, signing = publisher_factory

                # The publisher token is sent to the hub's URL, which may differ from its public URL.
                audience = [hub["url"], hub["public_url"]].reject(&.nil?).uniq
                additional_claims = if v1 && !signing["claims"]["aud"]
                                      %({"aud" => #{audience.size == 1 ? audience.first.stringify.id : audience}} of String => String | Array(String))
                                    else
                                      %({} of String => String | Array(String))
                                    end

                SERVICE_HASH[token_provider = "mercure_hub_#{name}_jwt_provider"] = {
                  class:      Athena::Mercure::TokenProvider::Factory,
                  tags:       ["mercure.jwt.provider"],
                  parameters: {
                    factory:           {value: "@#{decorated_factories[publisher_factory_id].id}"},
                    grants:            {value: %([AMC::Grant.new(:publish, #{publish.empty? ? "[] of String".id : publish}), AMC::Grant.new(:subscribe, #{subscribe.empty? ? "[] of String".id : subscribe})] of AMC::Grant).id},
                    additional_claims: {value: additional_claims.id},
                  },
                }
              end

              if token_factory
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
              hubs[name.stringify] = hub_id.id

              if (cfg["default_hub"] && cfg["default_hub"].id == name.id) || (!cfg["default_hub"] && default_hub_id == nil)
                default_hub_name = name
                default_hub_id = hub_id
              end

              SERVICE_HASH[hub_id] = {
                class:      Athena::Mercure::Hub,
                tags:       ["mercure.hub"],
                parameters: {
                  url:              {value: hub["url"]},
                  token_provider:   {value: "@#{token_provider.id}"},
                  token_factory:    {value: token_factory ? "@#{token_factory.id}" : nil},
                  public_url:       {value: hub["public_url"]},
                  cookie_name:      {value: hub["cookie_name"]},
                  protocol_version: {value: (v1 ? "Athena::Mercure::ProtocolVersion::V1" : "Athena::Mercure::ProtocolVersion::Legacy").id},
                },
              }

              hub_aliases << {id: hub_id, public: false, name: name}
              hub_aliases << {id: hub_id, public: false, name: "#{name}_hub"}
            end

            if cfg["default_hub"] && default_hub_id == nil
              cfg["default_hub"].raise "The 'mercure.default_hub' option refers to the '#{cfg["default_hub"].id}' hub, which is not defined. Defined hubs: '#{hubs.keys.join("', '").id}'."
            end

            hub_aliases << {id: default_hub_id, public: false}
            ALIASES[Athena::Mercure::Hub::Interface] = hub_aliases

            ALIASES[Athena::Mercure::TokenFactory::Interface] = token_factory_aliases unless token_factory_aliases.empty?
            ALIASES[Athena::Mercure::TokenProvider::Interface] = token_provider_aliases unless token_provider_aliases.empty?

            SERVICE_HASH[hub_registry_id = "mercure_hub_registry"] = {
              class: Athena::Mercure::Hub::Registry,
              # The hubs are provided as a raw hash literal, so reference them explicitly to keep the non-default ones from being removed as unused.
              referenced_services: hubs.values.map(&.stringify),
              parameters:          {
                default_hub: {value: default_hub_id.id},
                hubs:        {value: "#{hubs} of String => Athena::Mercure::Hub::Interface".id},
              },
            }

            SERVICE_HASH["mercure_authorization"] = {
              class:      Athena::Mercure::Bundle::Authorization,
              parameters: {
                hub_registry:    {value: hub_registry_id.id},
                cookie_lifetime: {value: cfg["default_cookie_lifetime"]},
              },
            }

            SERVICE_HASH["mercure_discovery"] = {
              class:      Athena::Mercure::Bundle::Discovery,
              parameters: {
                hub_registry: {value: hub_registry_id.id},
              },
            }

            SERVICE_HASH["mercure_add_link_header_listener"] = {
              class: Athena::Mercure::Bundle::Listeners::AddLinkHeader,
            }

            SERVICE_HASH["mercure_set_cookie_listener"] = {
              class: Athena::Mercure::Bundle::Listeners::SetCookie,
            }
          %}
        {% end %}
      end
    end
  end
end
