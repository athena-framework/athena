# Wraps an [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) instance to provide additional functionality.
#
# Forwards all additional methods to the wrapped `HTTP::Request` instance.
class Athena::Framework::Request
  @[Flags]
  enum ProxyHeader
    FORWARDED # RFC 7239
    FORWARDED_FOR
    FORWARDED_HOST
    FORWARDED_PROTO
    FORWARDED_PORT
    FORWARDED_PREFIX

    FORWARDED_AWS_ELB
    FORWARDED_TRAEFIK

    def header : String
      case self
      when .forwarded?        then "forwarded"
      when .forwarded_for?    then "x-forwarded-for"
      when .forwarded_host?   then "x-forwarded-host"
      when .forwarded_proto?  then "x-forwarded-proto"
      when .forwarded_port?   then "x-forwarded-port"
      when .forwarded_prefix? then "x-forwarded-prefix"
      else
        raise "BUG: requested header of unexpected proxy header type"
      end
    end

    def forwarded_param : String?
      case self
      when .forwarded_for?   then "for"
      when .forwarded_host?  then "host"
      when .forwarded_proto? then "proto"
      when .forwarded_port?  then "host"
      end
    end
  end

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

  class_getter trusted_header_set : ATH::Request::ProxyHeader = :none
  class_getter trusted_proxies : Array(String) = [] of String

  def self.set_trusted_proxies(@@trusted_proxies : Array(String), @@trusted_header_set : ATH::Request::ProxyHeader) : Nil
  end

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

  private getter trusted_proxies : Array(String)? do
    return if (trusted_proxies = @@trusted_proxies).empty?
    return unless (remote_address = self.remote_address)

    trusted_proxies.map do |proxy|
      "REMOTE_ADDRESS" == proxy ? remote_address : proxy
    end
  end

  @is_forwarded_valid : Bool = true

  @trusted_values_cache = Hash(String, Array(String)).new

  # :nodoc:
  forward_missing_to @request

  def self.new(method : String, path : String, headers : HTTP::Headers? = nil, body : String | Bytes | IO | Nil = nil, version : String = "HTTP/1.1") : self
    new HTTP::Request.new method.upcase, path, headers, body, version
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

  # Returns the port on which the request is made.
  #
  # TODO: Support reading the `#port` from the `X-Forwarded-Port` header if trusted.
  def port : Int32?
    unless host = @request.headers["host"]?
      return
    end

    pos = if host.starts_with? '['
            # Assume the host will have a closing `]` if it has a beginning one
            host.index ':', host.index!(']')
          else
            host.index ':'
          end

    if pos && (port = host[(pos + 1)..]?)
      return port.to_i
    end

    # Ideally should default this to something useful once we are able to know the scheme
    nil
  end

  # Returns the scheme of this request.
  def scheme : String
    self.secure? ? "https" : "http"
  end

  # Returns `true` the request was made over HTTPS, otherwise returns `false`
  #
  # TODO: Support reading the `#port` from the `X-Forwarded-Proto` header if trusted.
  def secure? : Bool
    if self.from_trusted_proxy? && (proto = self.get_trusted_values(ATH::Request::ProxyHeader::FORWARDED_PROTO))
      return proto[0].in? "https", "on", "ssl", "1"
    end

    # TODO: Possibly have this be based on if server was started with `bind_tls`
    # or if there is eventually some way to access TLS info off `@request`.
    false
  end

  def from_trusted_proxy? : Bool
    return false unless (trusted_proxies = self.trusted_proxies)
    return false unless (remote_address = self.remote_address)

    ATH::IPUtils.check remote_address, trusted_proxies
  end

  private def get_trusted_values(type : ATH::Request::ProxyHeader) : Array(String)
    cache_key = "#{type}-#{@@trusted_header_set.includes?(type) ? @request.headers[type.header]? : ""}-#{@request.headers[ProxyHeader::FORWARDED.header]?}"

    if result = @trusted_values_cache[cache_key]?
      return result
    end

    client_values = [] of String
    forwarded_values = [] of String

    if @@trusted_header_set.includes?(type) && (header_value = @request.headers[type.header]?)
      header_value.split(',').each do |part|
        client_values << "#{type.forwarded_port? ? "0.0.0.0" : ""}#{part.strip}"
      end
    end

    if @@trusted_header_set.includes?(ProxyHeader::FORWARDED) && (forwarded_param = type.forwarded_param) && (forwarded = @request.headers[ProxyHeader::FORWARDED.header]?)
      parts = ATH::HeaderUtils.split forwarded, ",;="
      param = type.forwarded_param

      parts.each do |sub_parts|
        # In this particular context compiler gets confused, so lets make it happy by skipping unexpected typed parts, which should never happen.
        next unless sub_parts.is_a?(Array(Array(String)))

        unless v = HeaderUtils.combine(sub_parts)[param]?.as?(String?)
          next
        end

        if type.forwarded_port?
          if v.ends_with?(']') || v.rindex(':').nil?
            v = self.secure? ? ":443" : ":80"
          end

          v = "0.0.0.0#{v}"
        end
        forwarded_values << v
      end
    end

    if forwarded_values == client_values || client_values.empty?
      return @trusted_values_cache[cache_key] = forwarded_values
    end

    if forwarded_values.empty?
      return @trusted_values_cache[cache_key] = client_values
    end

    unless @is_forwarded_valid
      return @trusted_values_cache[cache_key] = [] of String
    end
    @is_forwarded_valid = false

    raise "Oh noes"
  end

  private def remote_address : String?
    return unless (remote_address = @request.remote_address).is_a? Socket::IPAddress

    remote_address.address
  end

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse @request.body.try(&.gets_to_end) || ""
  end
end
