@[ADI::Register]
# Supports [Cross-Origin Resource Sharing](https://enable-cors.org) (CORS) requests.
#
# Handles CORS preflight `OPTIONS` requests as well as adding CORS headers to each response.
# See `ATH::Config::CORS` for information on configuring the listener.
#
# TIP: Set your [Log::Severity](https://crystal-lang.org/api/Log/Severity.html) to `TRACE` to help debug the listener.
struct Athena::Framework::Listeners::CORS
  include AED::EventListenerInterface

  # The [CORS-safelisted request-headers](https://fetch.spec.whatwg.org/#cors-safelisted-request-header).
  SAFELISTED_HEADERS = [
    "accept",
    "accept-language",
    "content-language",
    "content-type",
    "origin",
  ]

  # The [CORS-safelisted methods](https://fetch.spec.whatwg.org/#cors-safelisted-method).
  SAFELISTED_METHODS = [
    "GET",
    "POST",
    "HEAD",
  ]

  # :nodoc:
  ALLOW_SET_ORIGIN = "athena.routing.cors.allow_set_origin"

  private WILDCARD = "*"

  private REQUEST_METHOD_HEADER    = "access-control-request-method"
  private REQUEST_HEADERS_HEADER   = "access-control-request-headers"
  private ALLOW_CREDENTIALS_HEADER = "access-control-allow-credentials"
  private ALLOW_HEADERS_HEADER     = "access-control-allow-headers"
  private ALLOW_METHODS_HEADER     = "access-control-allow-methods"
  private ALLOW_ORIGIN_HEADER      = "access-control-allow-origin"
  private EXPOSE_HEADERS_HEADER    = "access-control-expose-headers"
  private MAX_AGE_HEADER           = "access-control-max-age"

  private getter! config : ATH::Config::CORS

  def initialize(@config : ATH::Config::CORS?); end

  @[AEDA::AsEventListener(priority: 250)]
  def on_request(event : ATH::Events::Request) : Nil
    request = event.request

    # Return early if there is no configuration.
    unless @config
      Log.trace { "#{self.class.name} is unconfigured, skipping CORS." }

      return
    end

    # Return early if not a CORS request.
    # TODO: optimize this by also checking if origin matches the request's host.
    unless request.headers.has_key? "origin"
      Log.trace { "Request does not have an 'origin' header, skipping CORS." }

      return
    end

    # If the request is a preflight, return the proper response.
    if request.method == "OPTIONS" && request.headers.has_key? REQUEST_METHOD_HEADER
      Log.trace { "Request is a pre-flight request, creating response." }

      return event.response = set_preflight_response event.request
    end

    unless check_origin event.request
      Log.trace { "Origin check failed." }

      return
    end

    Log.trace { "Origin is allowed, proceed with adding CORS response headers." }

    event.request.attributes.set ALLOW_SET_ORIGIN, true, Bool
  end

  @[AEDA::AsEventListener]
  def on_response(event : ATH::Events::Response) : Nil
    # Return early if the request shouldn't have CORS set.
    unless event.request.attributes.get? ALLOW_SET_ORIGIN
      Log.trace { "The origin is not allowed, skipping CORS response headers." }

      return
    end

    # Return early if there is no configuration.
    unless @config
      Log.trace { "#{self.class.name} is unconfigured, skipping CORS response headers." }

      return
    end

    origin = event.request.headers["origin"]

    Log.trace { "Setting '#{ALLOW_ORIGIN_HEADER}' to '#{origin}'." }

    # TODO: Add a configuration option to allow setting this explicitly
    event.response.headers[ALLOW_ORIGIN_HEADER] = origin

    if self.config.allow_credentials
      Log.trace { "Setting '#{ALLOW_CREDENTIALS_HEADER}' to 'true'." }

      event.response.headers[ALLOW_CREDENTIALS_HEADER] = "true"
    end

    unless self.config.expose_headers.empty?
      headers = self.config.expose_headers.join(", ")

      Log.trace { "Settings '#{EXPOSE_HEADERS_HEADER}' to '#{headers}'." }

      event.response.headers[EXPOSE_HEADERS_HEADER] = headers
    end
  end

  # Configures the given *response* for CORS preflight
  private def set_preflight_response(request : ATH::Request) : ATH::Response
    response = ATH::Response.new
    response.headers["vary"] = "origin"

    if self.config.allow_credentials
      Log.trace { "Setting '#{ALLOW_CREDENTIALS_HEADER}' response header to 'true'." }

      response.headers[ALLOW_CREDENTIALS_HEADER] = "true"
    end

    if self.config.max_age > 0
      max_age = self.config.max_age.to_s

      Log.trace { "Setting '#{MAX_AGE_HEADER}' response header to '#{max_age}'." }

      response.headers[MAX_AGE_HEADER] = max_age
    end

    unless self.config.allow_methods.empty?
      allow_methods = self.config.allow_methods.join(", ")

      Log.trace { "Setting '#{ALLOW_METHODS_HEADER}' response header to '#{allow_methods}'." }

      response.headers[ALLOW_METHODS_HEADER] = allow_methods
    end

    unless self.config.allow_headers.empty?
      headers : Array(String) = self.config.allow_headers.includes?(WILDCARD) ? (request.headers[REQUEST_HEADERS_HEADER]?.try &.split(/,\ ?/) || [] of String) : self.config.allow_headers

      unless headers.empty?
        allow_headers = headers.join(", ")

        Log.trace { "Setting '#{ALLOW_HEADERS_HEADER}' response header to '#{allow_headers}'." }

        response.headers[ALLOW_HEADERS_HEADER] = allow_headers
      end
    end

    unless check_origin request
      Log.trace { "Removing '#{ALLOW_ORIGIN_HEADER}' response header." }

      request.headers.delete ALLOW_ORIGIN_HEADER

      return response
    end

    origin = request.headers["origin"]

    Log.trace { "Setting '#{ALLOW_ORIGIN_HEADER}' response header to '#{origin}'." }

    response.headers[ALLOW_ORIGIN_HEADER] = origin

    unless self.config.allow_methods.includes?(method = request.headers[REQUEST_METHOD_HEADER].upcase)
      Log.trace { "Method '#{method}' is not allowed." }

      response.status = :method_not_allowed

      return response
    end

    unless self.config.allow_headers.includes? WILDCARD
      ((rh = request.headers[REQUEST_HEADERS_HEADER]?) ? rh.split(/,\ ?/) : [] of String).each do |header|
        next if SAFELISTED_HEADERS.includes? header
        next if self.config.allow_headers.includes? header

        raise ATH::Exceptions::Forbidden.new "Unauthorized header: '#{header}'."
      end
    end

    response
  end

  private def check_origin(request : ATH::Request) : Bool
    origin = request.headers["origin"]

    if self.config.allow_origin.includes?(WILDCARD)
      Log.trace { "Origin is a wildcard." }

      return true
    end

    # Use case equality in case an origin is a Regex
    self.config.allow_origin.each do |ao|
      Log.trace { "Checking allowed origin '#{ao}' to origin '#{origin}'." }

      if ao === origin
        Log.trace { "Allowed origin '#{ao}' matches origin '#{origin}'." }

        return true
      end
    end

    Log.trace { "Origin '#{origin}' is not allowed." }

    false
  end
end
