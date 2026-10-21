# Sets the `AHTTP::Session` of each request, which is only created once it is first used, and persists it once the response is ready.
#
# The session is identified by the request's session cookie.
# The cookie is set on the response when the session gets a new ID, and removed once the session is emptied, e.g. when logging out.
#
# A response to a request that used the session, or that sets or clears its cookie, is marked as private and must be revalidated, as it may contain data specific to the client.
# Set the `NO_AUTO_CACHE_CONTROL_HEADER` header on the response to opt out of this, e.g. if caching responses with session data makes sense.
#
# Using the session while handling a request whose route is declared [stateless](/Routing/Annotations/Route/) logs a warning,
# or raises an `AHK::Exception::UnexpectedSessionUsage` in debug mode.
class Athena::HTTPKernel::Listeners::Session
  # Disables marking the response as private if its request used the session.
  # The header itself is removed from the response.
  NO_AUTO_CACHE_CONTROL_HEADER = "athena-session-no-auto-cache-control"

  # Creates a listener using the provided *session_factory* to create the session of each request.
  #
  # The *cookie_path*, *cookie_domain*, *cookie_secure*, *cookie_http_only*, and *cookie_samesite* are the attributes of the session cookie.
  # A *cookie_secure* of `nil` only marks the cookie as secure if the request was made over HTTPS.
  # The cookie expires once the session's [lifetime](/HTTP/Session/Storage/MetadataBag/#Athena::HTTP::Session::Storage::MetadataBag#lifetime) has passed, if it has one.
  def initialize(
    @session_factory : AHTTP::Session::Factory,
    @debug : Bool = false,
    @cookie_path : String = "/",
    @cookie_domain : String? = nil,
    @cookie_secure : Bool? = nil,
    @cookie_http_only : Bool = true,
    @cookie_samesite : ::HTTP::Cookie::SameSite? = :lax,
  )
  end

  @[AEDA::AsEventListener(priority: 128)]
  def on_request(event : AHK::Events::Request) : Nil
    request = event.request

    return if request.has_session?

    request.session_factory = -> do
      session = @session_factory.create_session

      if cookie = request.cookies[session.name]?
        session.id = cookie.value
      end

      session
    end
  end

  # Runs after other response listeners, so that they can still use the session.
  @[AEDA::AsEventListener(priority: -1000)]
  def on_response(event : AHK::Events::Response) : Nil # ameba:disable Metrics/CyclomaticComplexity
    response = event.response
    auto_cache_control = !response.headers.has_key? NO_AUTO_CACHE_CONTROL_HEADER

    # Always remove the internal header if present.
    response.headers.delete NO_AUTO_CACHE_CONTROL_HEADER

    request = event.request

    return unless request.has_session? true

    session = request.session

    # Read before the cookie is set, as reading the session's lifetime counts as using it.
    # Setting or clearing the cookie also counts, e.g. when the session was only migrated, so that the response is not cached for other clients.
    session_used = !session.usage_index.zero?

    if session.started?
      # Persists the session before the response is sent, so that the client's next request, e.g. after a redirect, has its data.
      session.save

      session_name = session.name
      session_id = session.id
      request_session_cookie_id = request.cookies[session_name]?.try &.value.presence

      secure = @cookie_secure
      secure = request.secure? if secure.nil?

      is_session_empty = session.empty?

      if request_session_cookie_id && is_session_empty
        response.headers.clear_cookie session_name, @cookie_path, @cookie_domain, secure, @cookie_http_only, @cookie_samesite

        session_used = true
      elsif session_id != request_session_cookie_id && !is_session_empty
        expires = max_age = nil

        if (lifetime = session.metadata_bag.lifetime) > 0
          max_age = lifetime.seconds
          expires = Time.utc + max_age
        end

        response.headers << ::HTTP::Cookie.new(
          session_name,
          session_id,
          path: @cookie_path,
          expires: expires,
          domain: @cookie_domain,
          secure: secure,
          http_only: @cookie_http_only,
          samesite: @cookie_samesite,
          max_age: max_age,
        )

        session_used = true
      end
    end

    return unless session_used

    if auto_cache_control
      max_age = response.headers.has_cache_control_directive?("public") ? 0 : (response.max_age || 0)

      response.expires = Time.utc + max_age.seconds
      response.set_private
      response.max_age = max_age
      response.headers.add_cache_control_directive "must-revalidate"

      # Fields like CDN-Cache-Control replace Cache-Control for the caches they target (RFC 9213).
      # They are overwritten instead of removed, so that a 304 also updates the copy a CDN may have stored before.
      cache_control = response.headers["cache-control"]
      response.headers.select { |name, _| name.downcase.ends_with? "-cache-control" }.each do |name, _|
        response.headers[name] = cache_control
      end
    end

    return unless request.attributes.get? "_stateless", Bool

    raise AHK::Exception::UnexpectedSessionUsage.new "Session was used while the request was declared stateless." if @debug

    Log.warn { "Session was used while the request was declared stateless." }
  end
end
