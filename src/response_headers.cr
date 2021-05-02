# Wraps an [HTTP::Headers](https://crystal-lang.org/api/HTTP/Headers.html) instance to provide additional functionality.
#
# Forwards all additional methods to the wrapped `HTTP::Headers` instance.
class Athena::Routing::Response::Headers
  # Returns an [HTTP::Cookies](https://crystal-lang.org/api/HTTP/Cookies.html) instance that stores cookies related to `self`.
  getter cookies : HTTP::Cookies { HTTP::Cookies.new }

  # A Hash representing the current [cache-control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header directives.
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new
  @computed_cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  @headers = HTTP::Headers.new

  # :nodoc:
  forward_missing_to @headers

  # Utility constructor to allow calling `.new` with a union of `self` and `HTTP::Headers`.
  #
  # Returns the provided *headers* object.
  def self.new(headers : self) : self
    headers
  end

  # Creates a new `self`, including the data from the provided *headers*.
  def initialize(headers : HTTP::Headers = HTTP::Headers.new)
    @headers.merge! headers

    unless @headers.has_key? "cache-control"
      self.["cache-control"] = ""
    end

    # See https://tools.ietf.org/html/rfc2616#section-14.18.
    unless @headers.has_key? "date"
      self.init_date
    end
  end

  # Adds the provided *cookie* to the `#cookies` container.
  def <<(cookie : HTTP::Cookie) : Nil
    self.cookies << cookie
  end

  # Sets a cookie with the provided *key* and *value*.
  #
  # !!!note
  #     The *key* and cookie name must match.
  def []=(key : String, value : HTTP::Cookie) : Nil
    self.cookies[key] = value
  end

  # Sets a header with the provided *key* to the provided *value*.
  #
  # !!!note
  #     This method will override the *value* of the provided *key*.
  def []=(key : String, value : Array(String)) : Nil
    if "set-cookie" == key.downcase
      value.each do |v|
        if cookie = HTTP::Cookie::Parser.parse_set_cookie v
          self.cookies << cookie
        else
          raise ArgumentError.new "Invalid cookie header: #{v}."
        end
      end

      return
    end

    @headers[key] = value
  end

  # :ditto:
  def []=(key : String, value : String) : Nil
    if "set-cookie" == key.downcase
      if cookie = HTTP::Cookie::Parser.parse_set_cookie value
        self.cookies << cookie
      else
        raise ArgumentError.new "Invalid cookie header: #{value}."
      end

      return
    end

    @headers[key] = value

    if "cache-control" == key.downcase
      @cache_control = ART::HeaderUtils.parse value
    end

    if key.downcase.in?("cache-control", "etag", "last-modified", "expires") && (computed = self.compute_cache_control_value.presence)
      @headers["cache-control"] = computed
      @computed_cache_control = ART::HeaderUtils.parse computed
    end
  end

  # :ditto:
  def []=(key : String, value : _) : Nil
    self.[key] = value.to_s
  end

  # Returns `true` if `self` is equal to the provided `HTTP::Headers` instance.
  # Otherwise returns `false`.
  def ==(other : HTTP::Headers) : Bool
    @headers == other
  end

  # Adds the provided *value* to the the provided *key*.
  #
  # !!!note
  #     This method will concatenate the *value* to the provided *key*.
  def add(key : String, value : String) : Nil
    @headers.add key, value

    if "cache-control" == key.downcase
      @cache_control = ART::HeaderUtils.parse @headers["cache-control"]
      @headers["cache-control"] = self.cache_control_header
    end
  end

  # Adds the provided *directive*; updating the `cache-control` header.
  def add_cache_control_directive(directive : String, value : String | Bool = true)
    @cache_control[directive] = value == true ? value : value.to_s
    @headers["cache-control"] = self.cache_control_header
  end

  # Returns a `Time` instance by parsing the datetime string from the header with the provided *key*.
  #
  # Returns the provided *default* if no value with the provided *key* exists, or if parsing its value fails.
  #
  # ```
  # time = HTTP.format_time Time.utc 2021, 4, 7, 12, 0, 0
  # headers = ART::Response::Headers{"date" => time}
  #
  # headers.date                 # => 2021-04-07 12:00:00.0 UTC
  # headers.date "foo"           # => nil
  # headers.date "foo", Time.utc # => 2021-05-02 14:32:35.257505806 UTC
  # ```
  def date(key : String = "date", default : Time? = nil) : Time?
    unless time = @headers[key]?
      return default
    end

    HTTP.parse_time time
  end

  # Deletes the header with the provided *key*.
  #
  # Clears the `#cookies` instance if *key* is `set-cookie`.
  #
  # Clears the `cache-control` header if *key* is `cache-control`.
  #
  # Reinitializes the `date` header if *key* is `date`.
  def delete(key : String) : Nil
    if "set-cookie" == key.downcase
      return self.cookies.clear
    end

    @headers.delete key

    if "cache-control" == key.downcase
      @cache_control.clear
      @computed_cache_control.clear
    end

    if "date" == key.downcase
      self.init_date
    end
  end

  # Returns the provided [directive](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#directives) from the `cache-control` header, or `nil` if it is not set.
  def get_cache_control_directive(directive : String) : String | Bool | Nil
    @computed_cache_control[directive]?
  end

  # Returns `true` if the current `cache-control` header has the provided [directive](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#directives).
  # Otherwise returns `false`.
  def has_cache_control_directive?(directive : String) : Bool
    @computed_cache_control.has_key? directive
  end

  # Removes the provided [directive](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#directives) from the `cache-control` header.
  def remove_cache_control_directive(directive : String) : Nil
    @cache_control.delete directive
    @headers["cache-control"] = self.cache_control_header
  end

  private def compute_cache_control_value : String
    if @cache_control.empty?
      if @headers.has_key?("last-modified") || @headers.has_key?("expires")
        # Allows for heuristic expiration (RFC 7234 Section 4.2.2) in the case of "last-modified"
        return "private, must-revalidate"
      end

      # Be Conservative by default
      return "no-cache, private"
    end

    header = self.cache_control_header
    if @cache_control.has_key?("public") || @cache_control.has_key?("private")
      return header
    end

    # Public if s-maxage is defined, private otherwise
    unless @cache_control.has_key? "s-maxage"
      return "#{header}, private"
    end

    header
  end

  private def cache_control_header : String
    ART::HeaderUtils.to_string @cache_control, ", "
  end

  private def init_date : Nil
    @headers["date"] = HTTP.format_time Time.utc
  end
end
