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
#         },
#       },
#     },
#   },
# })
# ```
#
# See `Schema` for the full set of possible configuration options.
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
# Inject `AMC::Bundle::Authorization` to set the `mercureAuthorization` cookie for [private updates](/Mercure/#authorization).
# The `AMC::Bundle::Listeners::SetCookie` listener automatically adds the cookie to the response — there is no need to modify the response directly:
#
# ```
# @[ARTA::Route(path: "/auth")]
# class AuthController < ATH::Controller
#   def initialize(@authorization : AMC::Bundle::Authorization); end
#
#   @[ARTA::Get("/subscribe")]
#   def subscribe(request : AHTTP::Request) : Nil
#     @authorization.set_cookie(
#       request,
#       subscribe: ["https://example.com/books/{id}"],
#     )
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
#     hub.searchParams.append('topic', 'https://example.com/books/{id}');
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
    # Generating tokens requires the optional `jwt` shard, see the [installation](/Mercure/#installation) instructions.
    #
    # ---
    # >>secret: The secret key used to sign JWTs.
    # Required when generating tokens dynamically via a `AMC::TokenFactory::JWT` (i.e. when *value* is not set).
    # Should be set via ENV var.
    # >>publish: Topic selectors that the generated JWT grants publish access to. Included in the JWT's `mercure.publish` claim.
    # >>subscribe: Topic selectors that the generated JWT grants subscribe access to. Included in the JWT's `mercure.subscribe` claim.
    # >>algorithm: The signing algorithm used to encode the JWT, as the name of a [JWT::Algorithm](https://github.com/crystal-community/jwt#supported-algorithms) member, such as `:hs256` or `:rs256`.
    # >>passphrase: Passphrase for the secret key, if the algorithm requires one (e.g. RSA).
    # >>value: A pre-built static JWT token string provided via `AMC::TokenProvider::Static`. When set, the token is used as-is and *secret*, *algorithm*, and *passphrase* are ignored.
    # ---
    object_schema JWT,
      secret : String? = nil,
      publish : Array(String) = [] of String,
      subscribe : Array(String) = [] of String,
      algorithm : Symbol = :hs256,
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
            parameters = CONFIG["parameters"]

            default_hub_id = nil
            default_hub_name = nil
            hubs = {} of Nil => Nil

            hub_aliases = [] of Nil

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
                unless @top_level.has_constant?("JWT")
                  name.raise "Mercure hub '#{name.id}' generates JWTs, which requires the `jwt` shard. Add it to your `shard.yml` and `require \"jwt\"`, or use a static token via 'jwt.value'."
                end

                algorithms = parse_type("::JWT::Algorithm").resolve.constants.map(&.stringify.downcase)

                unless algorithms.includes? jwt["algorithm"].id.stringify.downcase
                  jwt["algorithm"].raise "Unknown JWT algorithm '#{jwt["algorithm"].id}' for Mercure hub '#{name.id}'. Expected one of: #{algorithms.join(", ").id}."
                end

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

                ALIASES[Athena::Mercure::TokenFactory::Interface] = [
                  {id: token_factory, public: false, name: name},
                  {id: token_factory, public: false, name: "#{name}_factory"},
                  {id: token_factory, public: false, name: "#{name}_token_factory"},
                ]
              end

              if token_provider
                ALIASES[Athena::Mercure::TokenProvider::Interface] = [
                  {id: token_provider, public: false, name: name},
                  {id: token_provider, public: false, name: "#{name}_provider"},
                  {id: token_provider, public: false, name: "#{name}_token_provider"},
                ]
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
                  token_factory:  {value: token_factory.id},
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

            SERVICE_HASH[hub_registry_id = "mercure_hub_registry"] = {
              class:      Athena::Mercure::Hub::Registry,
              parameters: {
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
