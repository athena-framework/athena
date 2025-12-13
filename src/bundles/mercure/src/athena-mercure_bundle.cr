require "athena-dependency_injection"
require "athena-http_kernel"
require "athena-mercure"

@[ADI::Bundle("mercure")]
struct Athena::MercureBundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  module Schema
    include ADI::Extension::Schema

    object_schema JWT,
      secret : String? = nil,
      publish : Array(String) = [] of String,
      subscribe : Array(String) = [] of String,
      algorithm : ::JWT::Algorithm = :hs256,
      passphrase : String = "",
      value : String? = nil

    map_of hubs,
      url : String,
      public_url : String? = nil,
      jwt : JWT

    property default_hub : String? = nil
    property default_cookie_lifetime : Int32 | Time::Span | Nil = nil
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
                  tags:       ["mercure.jwt.factory"],
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

              if (cfg["default_hub"] || name) == name
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

              ALIASES[Athena::Mercure::Hub::Interface] = [
                {id: hub_id, public: false, name: name},
                {id: hub_id, public: false, name: "#{name}_hub"},
              ]
            end

            ALIASES[Athena::Mercure::Hub::Interface] = [
              {id: default_hub_id, public: false},
            ]

            SERVICE_HASH[hub_registry_id = "mercure_hub_registry"] = {
              class:      Athena::Mercure::Hub::Registry,
              public:     true,
              parameters: {
                default_hub: {value: default_hub_id.id},
                hubs:        {value: "#{hubs} of String => Athena::Mercure::Hub::Interface".id},
              },
            }

            SERVICE_HASH["mercure_authorization"] = {
              class:      Athena::MercureBundle::Authorization,
              public:     true,
              parameters: {
                hub_registry:    {value: hub_registry_id.id},
                cookie_lifetime: {value: cfg["default_cookie_lifetime"]},
              },
            }

            SERVICE_HASH["mercure_discovery"] = {
              class:      Athena::MercureBundle::Discovery,
              public:     true,
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

@[ADI::Register]
struct Athena::MercureBundle::Listeners::SetCookie
  @[AEDA::AsEventListener]
  def on_response(event : AHK::Events::Response) : Nil
    return unless cookies = event.request.attributes.get? "_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)

    event.request.attributes.remove "_mercure_authorization_cookies"

    cookies.each_value do |cookie|
      event.response.headers << cookie
    end
  end
end

class Athena::MercureBundle::Authorization < Athena::Mercure::Authorization
  def initialize(
    hub_registry : AMC::Hub::Registry,
    cookie_lifetime : Time::Span = 1.hour,
    cookie_samesite : ::HTTP::Cookie::SameSite = :strict,
  )
    super
  end

  # :inherit:
  def set_cookie(
    request : AHTTP::Request,
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  )
    self.update_cookies request, hub_name, self.create_cookie(request, subscribe, publish, additional_claims, hub_name)
  end

  # :inherit:
  def clear_cookie(
    request : AHTTP::Request,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, hub_name, self.create_clear_cookie(request.request, hub_name)
  end

  # :inherit:
  def create_cookie(
    request : AHTTP::Request,
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  ) : ::HTTP::Cookie
    super request.request, subscribe, publish, additional_claims, hub_name
  end

  private def update_cookies(
    request : AHTTP::Request,
    hub_name : String?,
    cookie : ::HTTP::Cookie,
  ) : Nil
    hub_name ||= ""

    cookies = request.attributes.get?("_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)) || Hash(String, ::HTTP::Cookie).new

    if cookies.has_key? hub_name
      raise AMC::Exception::Runtime.new "The 'mercureAuthorization' cookie for the '#{hub_name.presence ? "#{hub_name} hub" : "default hub"}' has already been set. You cannot set it two times during the same request."
    end

    cookies[hub_name] = cookie

    request.attributes.set "_mercure_authorization_cookies", cookies, Hash(String, ::HTTP::Cookie)
  end
end

class Athena::MercureBundle::Discovery < AMC::Discovery
  def initialize(
    hub_registry : AMC::Hub::Registry,
  )
    super
  end

  # :inherit:
  def add_link(request : AHTTP::Request, hub_name : String? = nil) : Nil
    return if self.preflight_request? request.request

    hub = @hub_registry.hub hub_name

    # TODO: Create WebLink component?
    request.attributes.set("_links", [self.generate_link(hub.public_url)], Array(String))
  end
end

@[ADI::Register]
struct Athena::MercureBundle::Listeners::AddLinkHeader
  @[AEDA::AsEventListener]
  def on_response(event : AHK::Events::Response) : Nil
    return unless links = event.request.attributes.get? "_links", Array(String)

    # TODO: Create WebLink component?
    event.response.headers["link"] = links.join ','
  end
end

ADI.register_bundle Athena::MercureBundle

ADI.configure({
  mercure: {
    hubs: {
      default: {
        url: "http://localhost:3000/hub",
        jwt: {
          secret: "~ChangeThisMercureHubJWTSecretKey~",
        },
      },
    },
  },
})
