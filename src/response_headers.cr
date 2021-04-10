class Athena::Routing::Response::Headers
  # A Hash representing the current [cache-control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header directives.
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  @headers : HTTP::Headers

  # :nodoc:
  forward_missing_to @headers

  def initialize(@headers : HTTP::Headers = HTTP::Headers.new)
    if !@headers.has_key? "cache-control"
      self.["cache-control"] = ""
    end

    # See https://tools.ietf.org/html/rfc2616#section-14.18.
    if !@headers.has_key? "date"
      self.init_date
    end
  end

  # def []=(key : String, value : _) : Nil
  #   self.[key] = value.to_s
  # end

  def []=(key : String, value : String) : Nil
    @headers[key] = value

    if "cache-control" == key.underscore.downcase
      @cache_control = ART::HeaderUtils.parse value
    end

    if key.in?("cache-control", "etag", "last-modified", "expires") && (computed = self.compute_cache_control_value.presence)
      @headers["cache-control"] = computed
      @cache_control = ART::HeaderUtils.parse computed
    end
  end

  # Adds the provided *directive*; updating the `cache-control` header.
  def add_cache_control_directive(directive : String, value : String | Bool = true)
    @cache_control[directive] = value == true ? value : value.to_s
    @headers["cache-control"] = self.cache_control_header
  end

  def delete(key : String) : Nil
    @headers.delete key

    if "cache-control" == key.underscore.downcase
      @cache_control.clear
    end

    if "date" == key.underscore.downcase
      self.init_date
    end
  end

  # Returns `true` if the current `cache-control` header has the provided *directive*.
  # Otherwise returns `false`.
  def has_cache_control_directive?(directive : String) : Bool
    @cache_control.has_key? directive
  end

  # Removes the provided *directive* from the `cache-control` header, or `nil` if it is not set.
  def get_cache_control_directive(directive : String) : String | Bool | Nil
    @cache_control[directive]?
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
    if self.has_cache_control_directive?("public") || self.has_cache_control_directive?("private")
      return header
    end

    # Public if s-maxage is defined, private otherwise
    unless self.has_cache_control_directive? "s-maxage"
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
