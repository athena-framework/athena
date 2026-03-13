struct Athena::MercureBundle < ADI::AbstractBundle; end

# Extension of [AMC::Authorization](/Mercure/Authorization) to add support for [AHTTP::Request](/HTTP/Request).
class Athena::MercureBundle::Authorization < Athena::Mercure::Authorization
  def initialize(
    hub_registry : AMC::Hub::Registry,
    cookie_lifetime : Time::Span = 1.hour,
    cookie_samesite : ::HTTP::Cookie::SameSite = :strict,
  )
    super
  end

  # Sets the `mercureAuthorization` cookie for the provided *hub_name*.
  # The cookie is automatically applied to the `AHTTP::Response` via the `Listeners::SetCookie` listener.
  #
  # The JWT cookie value by default does not have access to publish or subscribe to any topic.
  # Be sure to set the *subscribe* and *publish* arrays to the topics you want it to be able to interact with, or `["*"]` to handle all topics.
  # *additional_claims* may also be used to define additional claims to the JWT if needed.
  def set_cookie(
    request : AHTTP::Request,
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, hub_name, self.create_cookie(request, subscribe, publish, additional_claims, hub_name)
  end

  # Clears the `mercureAuthorization` cookie for the given *hub_name*.
  def clear_cookie(
    request : AHTTP::Request,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, hub_name, self.create_clear_cookie(request.request, hub_name)
  end

  # Returns a Mercure auth cookie given the provided *request* and optionally for the provided *hub_name*.
  #
  # The JWT cookie value by default does not have access to publish or subscribe to any topic.
  # Be sure to set the *subscribe* and *publish* arrays to the topics you want it to be able to interact with, or `["*"]` to handle all topics.
  # *additional_claims* may also be used to define additional claims to the JWT if needed.
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
