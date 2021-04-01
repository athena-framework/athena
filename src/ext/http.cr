# :nodoc:
class HTTP::Request
  private FORMATS = {
    "html"   => Set{"text/html", "application/xhtml+xml"},
    "txt"    => Set{"text/plain"},
    "js"     => Set{"application/javascript", "application/x-javascript", "text/javascript"},
    "css"    => Set{"text/css"},
    "json"   => Set{"application/json", "application/x-json"},
    "jsonld" => Set{"application/ld+json"},
    "xml"    => Set{"text/xml", "application/xml", "application/x-xml"},
    "rdf"    => Set{"application/rdf+xml"},
    "atom"   => Set{"application/atom+xml"},
    "rss"    => Set{"application/rss+xml"},
    "form"   => Set{"application/x-www-form-urlencoded"},
  }

  def self.register_format(format : String, mime_types : Indexable(String)) : Nil
    FORMATS[format] = mime_types.to_set
  end

  def self.mime_types(format : String) : Set(String)
    FORMATS[format]? || Set(String).new
  end

  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! action : ART::ActionBase

  # See `ART::ParameterBag`.
  getter attributes : ART::ParameterBag = ART::ParameterBag.new

  @request_data : HTTP::Params?

  setter request_format : String? = nil

  def mime_type(format : String) : String?
    self.class.mime_types(format).first?
  end

  def format(mime_type : String) : String?
    canonical_mime_type = nil

    if mime_type.includes? ";"
      canonical_mime_type = mime_type.split(";").first.strip
    end

    FORMATS.each do |format, mime_types|
      return format if mime_types.includes? mime_type
      return format if canonical_mime_type && mime_types.includes? canonical_mime_type
    end
  end

  # Returns the host name the request originated from.
  #
  # In the future this will support reading the Host from the `X-Forwarded-Host` header if trusted.
  def hostname : String?
    previous_def
  end

  def request_data
    @request_data ||= self.parse_request_data
  end

  def request_format(default : String? = "json") : String?
    if @request_format.nil?
      @request_format = self.attributes.get? "_format", String
    end

    @request_format || default
  end

  # Returns `true` if this request"s `#method` is [safe](https://tools.ietf.org/html/rfc7231#section-4.2.1).
  # Otherwise returns `false`.
  def safe? : Bool
    @method.in? "GET", "HEAD", "OPTIONS", "TRACE"
  end

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse self.body.try(&.gets_to_end) || ""
  end
end

struct HTTP::Headers
  # A Hash representing the current [cache-control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header directives.
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  # Adds the provided *directive*; updating the `cache-control` header.
  def add_cache_control_directive(directive : String, value : String | Bool = true)
    @cache_control[directive] = value == true ? value : value.to_s
    self.["cache-control"] = self.cache_control_header
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
    self.["cache-control"] = self.cache_control_header
  end

  private def cache_control_header : String
    ART::HeaderUtils.to_string @cache_control, ", "
  end
end
