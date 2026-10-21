# Stores the cookies an `ATH::Spec::AbstractBrowser` received, sending the matching ones with its subsequent requests.
#
# Cookies are matched against the domain, path, and scheme of the request, and are removed once they expire.
class Athena::Framework::Spec::CookieJar
  private record Entry, cookie : ::HTTP::Cookie, host_only : Bool

  protected def self.more_specific?(cookie : ::HTTP::Cookie, other : ::HTTP::Cookie) : Bool
    path_length = (cookie.path || "/").size
    other_path_length = (other.path || "/").size

    if path_length != other_path_length
      return path_length > other_path_length
    end

    (cookie.domain || "").lstrip('.').size > (other.domain || "").lstrip('.').size
  end

  protected def self.domain_matches?(host : String, cookie_domain : String) : Bool
    host = host.downcase
    cookie_domain = cookie_domain.downcase.lstrip('.')

    host == cookie_domain || (host.ends_with?(".#{cookie_domain}") && !Socket::IPAddress.valid?(host))
  end

  protected def self.path_matches?(cookie_path : String, request_path : String) : Bool
    return true if cookie_path == request_path

    request_path.starts_with?(cookie_path) && (cookie_path.ends_with?('/') || '/' == request_path[cookie_path.size])
  end

  # Domain => Path => Name => Entry
  @cookie_jar = Hash(String, Hash(String, Hash(String, Entry))).new

  # Stores the provided *cookie*, replacing any cookie with the same name, path, and domain.
  def set(cookie : ::HTTP::Cookie) : Nil
    self.set cookie, host_only: false
  end

  private def set(cookie : ::HTTP::Cookie, host_only : Bool) : Nil
    domain_cookies = @cookie_jar.put_if_absent(cookie.domain || "") { Hash(String, Hash(String, Entry)).new }
    path_cookies = domain_cookies.put_if_absent(cookie.path || "/") { Hash(String, Entry).new }
    path_cookies[cookie.name] = Entry.new cookie, host_only
  end

  # Returns the most specific cookie with the provided *name* that matches the provided *path* and *domain*, or `nil` if there is none.
  def get(name : String, path : String = "/", domain : String? = nil) : ::HTTP::Cookie?
    self.flush_expired_cookies

    match = nil

    @cookie_jar.each do |cookie_domain, path_cookies|
      if !cookie_domain.empty? && domain
        cookie_domain = ".#{cookie_domain.lstrip('.')}"
        next unless ".#{domain}".ends_with? cookie_domain
      end

      path_cookies.each do |cookie_path, named_cookies|
        next if !self.class.path_matches?(cookie_path, path) || !(entry = named_cookies[name]?)
        next if domain && entry.host_only && domain.lstrip('.') != entry.cookie.domain

        if match.nil? || self.class.more_specific?(entry.cookie, match)
          match = entry.cookie
        end
      end
    end

    match
  end

  # Removes the cookie with the provided *name*, *path*, and *domain*.
  # Removes it from all domains if *domain* is `nil`.
  def expire(name : String, path : String? = "/", domain : String? = nil) : Nil
    path ||= "/"

    domains = domain.presence ? [domain] : @cookie_jar.keys

    domains.each do |cookie_domain|
      next unless path_cookies = @cookie_jar[cookie_domain]?

      if named_cookies = path_cookies[path]?
        named_cookies.delete name
        path_cookies.delete path if named_cookies.empty?
      end

      @cookie_jar.delete cookie_domain if path_cookies.empty?
    end
  end

  # Removes all cookies.
  def clear : Nil
    @cookie_jar.clear
  end

  # Stores the cookies set by the provided *response*.
  #
  # Cookies without a domain or path default to those of the provided *uri*, and are ignored if they do not match its host.
  def update_from_response(response : ::HTTP::Server::Response, uri : URI? = nil) : Nil
    host = uri.try &.host

    response.cookies.each do |response_cookie|
      cookie = response_cookie.dup
      host_only = false

      if uri && host
        unless cookie.domain.presence
          cookie.domain = host
          host_only = true
        end

        unless cookie.path.try &.starts_with?('/')
          cookie.path = (uri_path = uri.path).empty? ? "" : uri_path[0, uri_path.rindex('/') || 0]
        end
      end

      # Ignore the secure flag if the original URI is not HTTPS.
      cookie.secure = false if cookie.secure && "https" != uri.try(&.scheme)

      if host.nil? || self.class.domain_matches?(host, cookie.domain || "")
        self.set cookie, host_only
      end
    end
  end

  # Returns all non-expired cookies.
  def all : Array(::HTTP::Cookie)
    self.flush_expired_cookies

    cookies = [] of ::HTTP::Cookie

    @cookie_jar.each_value do |path_cookies|
      path_cookies.each_value do |named_cookies|
        named_cookies.each_value do |entry|
          cookies << entry.cookie
        end
      end
    end

    cookies
  end

  # Returns the name and value of the most specific cookie of each name that should be sent with a request to the provided *uri*.
  def all_values(uri : URI) : Hash(String, String)
    self.flush_expired_cookies

    uri_host = uri.host || ""
    uri_path = uri.path.presence || "/"
    cookies = Hash(String, ::HTTP::Cookie).new

    @cookie_jar.each do |domain, path_cookies|
      unless domain.empty?
        domain = ".#{domain.lstrip('.')}"
        next unless ".#{uri_host}".ends_with? domain
      end

      path_cookies.each do |path, named_cookies|
        next unless self.class.path_matches? path, uri_path

        named_cookies.each_value do |entry|
          cookie = entry.cookie

          next if cookie.secure && "https" != uri.scheme
          next if entry.host_only && uri_host != cookie.domain

          if !(existing = cookies[cookie.name]?) || self.class.more_specific?(cookie, existing)
            cookies[cookie.name] = cookie
          end
        end
      end
    end

    cookies.transform_values &.value
  end

  # Removes all expired cookies.
  def flush_expired_cookies : Nil
    @cookie_jar.each_value do |path_cookies|
      path_cookies.each_value do |named_cookies|
        named_cookies.reject! { |_, entry| entry.cookie.expired? }
      end
    end
  end
end
