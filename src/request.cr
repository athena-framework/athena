# Wraps an [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) instance to provide additional functionality.
#
# Forwards all additional methods to the wrapped `HTTP::Request` instance.
class Athena::Routing::Request
  # Represents the supported built in formats; mapping the format name to its valid `MIME` types.
  #
  # Additional formats may be registered via `#register_format`.
  FORMATS = {
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

  # Registers the provided *format* with the provided *mime_types*.
  def self.register_format(format : String, mime_types : Indexable(String)) : Nil
    FORMATS[format] = mime_types.to_set
  end

  # Returns the `MIME` types for the provided *format*.
  def self.mime_types(format : String) : Set(String)
    FORMATS[format]? || Set(String).new
  end

  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved
  # as part of `ART::Listeners::Routing`.
  getter! action : ART::ActionBase

  # See `ART::ParameterBag`.
  getter attributes : ART::ParameterBag = ART::ParameterBag.new

  @request_data : HTTP::Params?

  # Sets the `#request_format` to the explicitly passed format.
  setter request_format : String? = nil

  forward_missing_to @request

  # :nodoc:
  macro method_missing(call)
    previous_def
  end

  def self.new(method : String, path : String, headers : HTTP::Headers? = nil, body : String | Bytes | IO | Nil = nil, version : String = "HTTP/1.1") : self
    new HTTP::Request.new method, path, headers, body, version
  end

  def initialize(@request : HTTP::Request); end

  # :nodoc:
  def action=(@action : ART::ActionBase); end

  # Returns the first `MIME` type for the provided *format* if defined,
  # otherwise returns `nil`.
  def mime_type(format : String) : String?
    self.class.mime_types(format).first?
  end

  # Returns the format for the provided *mime_type*.
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
  # !!!todo
  #     Support reading the `#hostname` from the `X-Forwarded-Host` header if trusted.
  def hostname : String?
    @request.hostname
  end

  # Returns an `HTTP::Params` instance based on this request's form data body.
  def request_data
    @request_data ||= self.parse_request_data
  end

  # Returns the format for this request.
  #
  # First checks if a format was explicitly set via `#request_format=`.
  # Next, will check for the `_format` request `#attributes`, finally
  # falling back on the provided *default*.
  def request_format(default : String? = "json") : String?
    if @request_format.nil?
      @request_format = self.attributes.get? "_format", String
    end

    @request_format || default
  end

  # Returns `true` if this request's `#method` is [safe](https://tools.ietf.org/html/rfc7231#section-4.2.1).
  # Otherwise returns `false`.
  def safe? : Bool
    @request.method.in? "GET", "HEAD", "OPTIONS", "TRACE"
  end

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse @request.body.try(&.gets_to_end) || ""
  end
end
