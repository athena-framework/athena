# !!!warning
#    This type does _NOT_ support [hash like](https://crystal-lang.org/reference/syntax_and_semantics/literals/hash.html#hash-like-type-literal) syntax,
#    the Hash based `.new` overload instead.
#
# !!!todo
#     Figure out if there's a way to support the `hash like` syntax.
class Athena::Routing::Response::Headers
  getter cookies : HTTP::Cookies { HTTP::Cookies.new }

  # A Hash representing the current [cache-control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header directives.
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new
  @computed_cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  @headers = HTTP::Headers.new

  # :nodoc:
  forward_missing_to @headers

  def self.new(headers : self) : self
    headers
  end

  def self.new(header_hash : Hash(String, String)) : self
    new HTTP::Headers.new.merge! header_hash
  end

  def self.new(header_hash : Hash(String, _)) : self
    new header_hash.transform_values! &.to_s
  end

  def initialize(headers : HTTP::Headers = HTTP::Headers.new)
    headers.each do |k, v|
      self.[k] = v.first
    end

    unless @headers.has_key? "cache-control"
      self.["cache-control"] = ""
    end

    # See https://tools.ietf.org/html/rfc2616#section-14.18.
    unless @headers.has_key? "date"
      self.init_date
    end
  end

  def []=(key : String, value : HTTP::Cookie) : Nil
    self.cookies[key] = value
  end

  def []=(key : String, value : String) : Nil
    if "set-cookie" == key.downcase
      # TODO: Use HTTP::Cookie.from_header after https://github.com/crystal-lang/crystal/pull/10647 is merged.
      if cookie = HTTP::Cookie::Parser.parse_set_cookie value
        self.cookies << cookie
      else
        raise ArgumentError.new "Invalid cookie header: #{value}."
      end
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

  def []=(key : String, value : _) : Nil
    self.[key] = value.to_s
  end

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

  def date(key : String = "date", default : Time? = nil) : Time?
    unless time = @headers[key]?
      return default
    end

    HTTP.parse_time time
  end

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

  # Returns `true` if the current `cache-control` header has the provided *directive*.
  # Otherwise returns `false`.
  def has_cache_control_directive?(directive : String) : Bool
    @computed_cache_control.has_key? directive
  end

  # Removes the provided *directive* from the `cache-control` header, or `nil` if it is not set.
  def get_cache_control_directive(directive : String) : String | Bool | Nil
    @computed_cache_control[directive]?
  end

  # Removes the provided *directive* from the `cache-control` header.
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
