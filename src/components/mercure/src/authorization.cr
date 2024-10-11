class Athena::Mercure::Authorization
  private COOKIE_NAME = "mercureAuthorization"

  def initialize(
    @hub_registry : AMC::Hub::Registry,
    @cookie_lifetime : Time::Span = 1.hour,
    @cookie_samesite : HTTP::Cookie::SameSite = :strict,
  ); end

  def set_cookie(
    request : HTTP::Request,
    response : HTTP::Server::Response,
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  )
    self.update_cookies request, response, hub_name, self.create_cookie(request, subscribe, publish, additional_claims, hub_name)
  end

  def clear_cookie(
    request : HTTP::Request,
    response : HTTP::Server::Response,
    hub_name : String? = nil,
  ) : Nil
    self.update_cookies request, response, hub_name, self.create_clear_cookie(request, hub_name)
  end

  def create_cookie(
    request : HTTP::Request,
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
    hub_name : String? = nil,
  ) : HTTP::Cookie
    hub = @hub_registry.hub hub_name
    unless token_factory = hub.token_factory
      raise AMC::Exception::InvalidArgument.new "The hub '#{hub_name}' does not contain a token factory."
    end

    cookie_lifetime = @cookie_lifetime

    if additional_claims && (cl = additional_claims["exp"]?)
      cookie_lifetime = case cl
                        when String then cl.to_i.seconds
                        when Number then cl.seconds
                        else
                          @cookie_lifetime
                        end
    end

    token = token_factory.create subscribe, publish, additional_claims
    uri = URI.parse hub.public_url

    HTTP::Cookie.new(
      COOKIE_NAME,
      token,
      uri.path || "/",
      domain: self.cookie_domain(request, uri),
      secure: true,
      http_only: true,
      samesite: @cookie_samesite,
      max_age: cookie_lifetime
    )
  end

  private def create_clear_cookie(request : HTTP::Request, hub_name : String? = nil) : HTTP::Cookie
    hub = @hub_registry.hub hub_name
    uri = URI.parse hub.public_url

    HTTP::Cookie.new(
      COOKIE_NAME,
      "",
      uri.path || "/",
      domain: self.cookie_domain(request, uri),
      secure: true,
      http_only: true,
      samesite: @cookie_samesite,
      max_age: 1.second
    )
  end

  private def cookie_domain(request : HTTP::Request, uri : URI) : String?
    return unless uri_host = uri.host

    cookie_domain = uri_host.downcase
    host = request.hostname || ""

    return if cookie_domain == host

    if cookie_domain.ends_with? ".#{host}"
      return host
    end

    host_segments = host.split '.'

    host_segments[0..-2].each_with_index do |_, idx|
      current_domain = host_segments[idx..].join '.'

      target = ".#{current_domain}"

      if current_domain == cookie_domain || cookie_domain.ends_with? target
        return target
      end
    end

    raise AMC::Exception::InvalidArgument.new "Unable to create authorization cookie for a hub on the different second-level domain '#{cookie_domain}'."
  end

  private def update_cookies(
    request : HTTP::Request,
    response : HTTP::Server::Response,
    hub_name : String?,
    cookie : HTTP::Cookie,
  ) : Nil
    unless response.cookies[COOKIE_NAME]?.nil?
      raise AMC::Exception::Runtime.new "The 'mercureAuthorization' cookie for the '#{hub_name ? "#{hub_name} hub" : "default hub"}' has already been set. You cannot set it two times during the same request."
    end

    response.cookies << cookie
  end
end
