@[ADI::Register]
# Handles [Cross-Origin Resource Sharing](https://enable-cors.org) (CORS).
#
# Handles CORS preflight `OPTIONS` requests as well as adding CORS headers to each response.
# See `ATH::Config::CORS` for information on configuring the listener.
struct Athena::Framework::Listeners::CORS
  include AED::EventListenerInterface

  # Encapsulates logic to set CORS response headers
  private struct ResponseHeaders
    def initialize(@headers : ATH::Response::Headers); end

    {% for header in %w[allow-origin allow-methods allow-headers allow-credentials expose-headers] %}
      {% method_name = header.tr("-", "_").id %}
      def {{method_name}}=(value : String) : Nil
        @headers[{{"access-control-#{header.id}"}}] = value
      end

      def {{method_name}}=(value : Bool) : Nil
        return unless value
        self.{{method_name}} = "true"
      end

      def {{method_name}}=(value : Array(String)) : Nil
        return if value.empty?
        self.{{method_name}} = value.join ", "
      end

      def {{method_name}}=(value : Nil) : Nil
      end

      def delete_{{method_name}} : Nil
        @headers.delete({{"access-control-#{header.id}"}})
      end
    {% end %}

    def max_age=(value : Int32) : Nil
      return unless value > 0
      @headers["access-control-max-age"] = value.to_s
    end

    def vary=(value : String) : Nil
      @headers["vary"] = value
    end
  end

  # Encapsulates logic to query CORS request headers
  private struct RequestHeaders
    def initialize(@headers : HTTP::Headers); end

    def request_method : String?
      @headers["access-control-request-method"]?.try &.upcase
    end

    def request_headers : Array(String)
      @headers["access-control-request-headers"]?.try(&.split(/,\ ?/)) || [] of String
    end

    def origin : String?
      @headers["origin"]?
    end

    def has_request_method? : Bool
      @headers.has_key? "access-control-request-method"
    end
  end

  # :nodoc:
  ALLOW_SET_ORIGIN = "athena.routing.cors.allow_set_origin"
  private WILDCARD         = "*"

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

  private getter! config : ATH::Config::CORS?

  def initialize(@config : ATH::Config::CORS?); end

  @[AEDA::AsEventListener(priority: 250)]
  def on_request(event : ATH::Events::Request) : Nil
    request = event.request
    request_headers = RequestHeaders.new(request.headers)

    # Return early if there is no configuration.
    return unless @config

    # Return early if not a CORS request.
    # TODO: optimize this by also checking if origin matches the request's host.
    return unless request.headers.has_key? "origin"

    # If the request is a preflight, return the proper response.
    if request.method == "OPTIONS" && request_headers.has_request_method?
      return event.response = set_preflight_response event.request
    end

    return unless check_origin event.request

    event.request.attributes.set ALLOW_SET_ORIGIN, true, Bool
  end

  @[AEDA::AsEventListener]
  def on_response(event : ATH::Events::Response) : Nil
    # Return early if the request shouldn't have CORS set.
    return unless event.request.attributes.get? ALLOW_SET_ORIGIN

    # Return early if there is no configuration.
    return unless @config

    request_headers = RequestHeaders.new(event.request.headers)
    response_headers = ResponseHeaders.new(event.response.headers)

    # TODO: Add a configuration option to allow setting this explicitly
    response_headers.allow_origin = request_headers.origin
    response_headers.allow_credentials = self.config.allow_credentials
    response_headers.expose_headers = self.config.expose_headers
  end

  # Configures the given *response* for CORS preflight
  private def set_preflight_response(request : ATH::Request) : ATH::Response
    response = ATH::Response.new

    response_headers = ResponseHeaders.new(response.headers)
    request_headers = RequestHeaders.new(request.headers)

    response_headers.vary = "origin"
    response_headers.allow_credentials = self.config.allow_credentials
    response_headers.max_age = self.config.max_age
    response_headers.allow_methods = self.config.allow_methods

    response_headers.allow_headers = self.config.allow_headers.includes?(WILDCARD) ? request_headers.request_headers : self.config.allow_headers

    unless check_origin request
      response_headers.delete_allow_origin

      return response
    end

    response_headers.allow_origin = request_headers.origin

    unless self.config.allow_methods.includes? request_headers.request_method
      response.status = :method_not_allowed

      return response
    end

    unless self.config.allow_headers.includes? WILDCARD
      request_headers.request_headers.each do |header|
        next if SAFELISTED_HEADERS.includes? header
        next if self.config.allow_headers.includes? header

        raise ATH::Exceptions::Forbidden.new "Unauthorized header: '#{header}'"
      end
    end

    response
  end

  private def check_origin(request : ATH::Request) : Bool
    return true if self.config.allow_origin.includes?(WILDCARD)

    # Use case equality in case an origin is a Regex
    self.config.allow_origin.any? &.===(request.headers["origin"])
  end
end
