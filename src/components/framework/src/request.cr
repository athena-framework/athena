# Wraps an [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) instance to provide additional functionality.
#
# Forwards all additional methods to the wrapped `HTTP::Request` instance.
class Athena::Framework::Request
  # Represents the supported built in formats; mapping the format name to its valid `MIME` type(s).
  #
  # Additional formats may be registered via `.register_format`.
  FORMATS = {
    "atom"   => Set{"application/atom+xml"},
    "css"    => Set{"text/css"},
    "csv"    => Set{"text/csv"},
    "form"   => Set{"application/x-www-form-urlencoded"},
    "html"   => Set{"text/html", "application/xhtml+xml"},
    "js"     => Set{"application/javascript", "application/x-javascript", "text/javascript"},
    "json"   => Set{"application/json", "application/x-json"},
    "jsonld" => Set{"application/ld+json"},
    "rdf"    => Set{"application/rdf+xml"},
    "rss"    => Set{"application/rss+xml"},
    "txt"    => Set{"text/plain"},
    "xml"    => Set{"text/xml", "application/xml", "application/x-xml"},
  }

  # Registers the provided *format* with the provided *mime_types*.
  # Can also be used to change the *mime_types* supported for an existing *format*.
  #
  # ```
  # ATH::Request.register_format "some_format", {"some/mimetype"}
  # ```
  def self.register_format(format : String, mime_types : Indexable(String)) : Nil
    FORMATS[format] = mime_types.to_set
  end

  # Returns the `MIME` types for the provided *format*.
  #
  # ```
  # ATH::Request.mime_types "txt" # => Set{"text/plain"}
  # ```
  def self.mime_types(format : String) : Set(String)
    FORMATS[format]? || Set(String).new
  end

  # The `ATH::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved
  # as part of `ATH::Listeners::Routing`.
  getter! action : ATH::ActionBase

  # See `ATH::ParameterBag`.
  getter attributes : ATH::ParameterBag = ATH::ParameterBag.new

  @request_data : HTTP::Params?

  # Sets the `#request_format` to the explicitly passed format.
  setter request_format : String? = nil

  # Returns the raw wrapped `HTTP::Request` instance.
  getter request : HTTP::Request

  # :nodoc:
  forward_missing_to @request

  def self.new(method : String, path : String, headers : HTTP::Headers? = nil, body : String | Bytes | IO | Nil = nil, version : String = "HTTP/1.1") : self
    new HTTP::Request.new method, path, headers, body, version
  end

  def self.new(request : self) : self
    request
  end

  def initialize(@request : HTTP::Request); end

  # :nodoc:
  def action=(@action : ATH::ActionBase); end

  # Returns the first `MIME` type for the provided *format* if defined, otherwise returns `nil`.
  #
  # ```
  # request.mime_type "txt" # => "text/plain"
  # ```
  def mime_type(format : String) : String?
    self.class.mime_types(format).first?
  end

  # Returns the format for the provided *mime_type*.
  #
  # ```
  # request.format "text/plain" # => "txt"
  # ```
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
  # TODO: Support reading the `#hostname` from the `X-Forwarded-Host` header if trusted.
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
