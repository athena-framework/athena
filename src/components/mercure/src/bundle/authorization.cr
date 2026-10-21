# Extension of `AMC::Authorization` to add support for [AHTTP::Request](/HTTP/Request/).
class Athena::Mercure::Bundle::Authorization < Athena::Mercure::Authorization
  def initialize(
    hub_registry : AMC::Hub::Registry,
    cookie_lifetime : Time::Span = 1.hour,
    cookie_samesite : ::HTTP::Cookie::SameSite = :strict,
  )
    super
  end

  # Sets the authorization cookie of the provided *hub_name*, see `AMC::Hub::Interface#cookie_name`.
  # The cookie is automatically applied to the `AHTTP::Response` via the `Listeners::SetCookie` listener.
  #
  # The JWT cookie value by default does not have access to publish or subscribe to any topic.
  # Be sure to provide the *grants* it should have, such as the topics to subscribe to, or `["*"]` to subscribe to all topics.
  # See `AMC::Grant.from` for the accepted shorthands.
  # *additional_claims* may also be used to define additional claims to the JWT if needed.
  def set_cookie(
    request : AHTTP::Request,
    grants : Array(AMC::Grant) | Array(String) | Hash(String, Array(String)) | String = [] of AMC::Grant,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, hub_name, self.create_cookie(request, grants, additional_claims, hub_name)
  end

  # Clears the authorization cookie of the given *hub_name*.
  def clear_cookie(
    request : AHTTP::Request,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, hub_name, self.create_clear_cookie(request.request, hub_name)
  end

  # Returns a Mercure auth cookie given the provided *request* and optionally for the provided *hub_name*.
  #
  # The JWT cookie value by default does not have access to publish or subscribe to any topic.
  # Be sure to provide the *grants* it should have, such as the topics to subscribe to, or `["*"]` to subscribe to all topics.
  # See `AMC::Grant.from` for the accepted shorthands.
  # *additional_claims* may also be used to define additional claims to the JWT if needed.
  def create_cookie(
    request : AHTTP::Request,
    grants : Array(AMC::Grant) | Array(String) | Hash(String, Array(String)) | String = [] of AMC::Grant,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  ) : ::HTTP::Cookie
    super request.request, grants, additional_claims, hub_name
  end

  private def update_cookies(
    request : AHTTP::Request,
    hub_name : String?,
    cookie : ::HTTP::Cookie,
  ) : Nil
    hub_name ||= ""

    cookies = request.attributes.get?("_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)) || Hash(String, ::HTTP::Cookie).new

    if cookies.has_key? hub_name
      raise AMC::Exception::Runtime.new "The '#{cookie.name}' cookie for the '#{hub_name.presence ? "#{hub_name} hub" : "default hub"}' has already been set. You cannot set it two times during the same request."
    end

    cookies[hub_name] = cookie

    request.attributes.set "_mercure_authorization_cookies", cookies, Hash(String, ::HTTP::Cookie)
  end
end
