# Wraps an [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) instance to provide additional functionality.
#
# Forwards all additional methods to the wrapped [`HTTP::Request`](https://crystal-lang.org/api/HTTP/Request.html) instance.
class Athena::Framework::Request
  # Represents the supported [Proxy Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Proxy_servers_and_tunneling#forwarding_client_information_through_proxies).
  # Can be used via `ATH::Request.set_trusted_proxies` to whitelist which headers are allowed.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  @[Flags]
  enum ProxyHeader
    # The [`forwarded`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded) header as defined by [RFC 7239](https://datatracker.ietf.org/doc/html/rfc7239).
    FORWARDED

    # The [`x-forwarded-for`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For) header.
    FORWARDED_FOR

    # The [`x-forwarded-host`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Host) header.
    FORWARDED_HOST

    # The [`x-forwarded-proto`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Proto) header.
    FORWARDED_PROTO

    # Similar to `FORWARDED_HOST`, but exclusive to the port number.
    FORWARDED_PORT

    # Returns the string header name for a given proxy header.
    #
    # ```
    # ATH::Request::ProxyHeader::FORWARDED_PROTO.header => "x-forwarded-proto"
    # ```
    def header : String
      if override = ATH::Request.trusted_header_overrides[self]?
        return override
      end

      case self
      when .forwarded?       then "forwarded"
      when .forwarded_for?   then "x-forwarded-for"
      when .forwarded_host?  then "x-forwarded-host"
      when .forwarded_proto? then "x-forwarded-proto"
      when .forwarded_port?  then "x-forwarded-port"
      else
        raise "BUG: requested header of unexpected proxy header type"
      end
    end

    # Returns the `forwarded` param related to a given proxy header.
    #
    # ```
    # ATH::Request::ProxyHeader::FORWARDED_PROTO.forwarded_param => "proto"
    # ```
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
    "form"   => Set{"application/x-www-form-urlencoded", "multipart/form-data"},
    "html"   => Set{"text/html", "application/xhtml+xml"},
    "js"     => Set{"application/javascript", "application/x-javascript", "text/javascript"},
    "json"   => Set{"application/json", "application/x-json"},
    "jsonld" => Set{"application/ld+json"},
    "rdf"    => Set{"application/rdf+xml"},
    "rss"    => Set{"application/rss+xml"},
    "txt"    => Set{"text/plain"},
    "xml"    => Set{"text/xml", "application/xml", "application/x-xml"},
  }

  # Returns which `ATH::Request::ProxyHeader`s have been whitelisted by the application as set via `.set_trusted_proxies`, defaulting to all of them.
  class_getter trusted_header_set : ATH::Request::ProxyHeader = :all

  # Returns the list of trusted proxy IP addresses as set via `.set_trusted_proxies`.
  class_getter trusted_proxies : Array(String) = [] of String

  protected class_getter trusted_header_overrides : Hash(ATH::Request::ProxyHeader, String) = {} of ATH::Request::ProxyHeader => String

  # Allows setting a list of *trusted_proxies*, and which `ATH::Request::ProxyHeader` should be whitelisted.
  # The provided proxies are expected to be either IPv4 and/or IPv6 addresses.
  # The special `"REMOTE_ADDRESS"` string is also supported that will map to the current request's remote address.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  def self.set_trusted_proxies(trusted_proxies : Enumerable(String), @@trusted_header_set : ATH::Request::ProxyHeader) : Nil
    @@trusted_proxies = trusted_proxies.to_a
  end

  # Allows overriding the header name to look for off the request for a given `ATH::Request::ProxyHeader`.
  # In some cases a proxy might not use the exact `x-forwarded-*` header name.
  #
  # See the [external documentation](/Framework/guides/proxies/#custom-headers) for more information.
  def self.override_trusted_header(header : ATH::Request::ProxyHeader, name : String) : Nil
    @@trusted_header_overrides[header] = name
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

  @is_host_valid : Bool = true
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
  # Supports reading from `ATH::Request::ProxyHeader::FORWARDED_HOST`, falling back on the `"host"` header.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  def host : String?
    if self.from_trusted_proxy? && (host = self.get_trusted_values(ProxyHeader::FORWARDED_HOST)) && !host.empty?
      host = host.first
    elsif !(host = @request.headers["host"]?)
      return
    end

    # Trim and ensure there is no port number
    # downcase as per RFC 952/2181
    host = host.strip.gsub(/:\d+$/, "").downcase

    # Ensure host does not contain forbidden characters as pert RFC 952/2181
    if host.presence && !host.gsub(/(?:^\[)?[a-zA-Z0-9-:\]_]+\.?/, "").empty?
      return unless @is_host_valid
      @is_host_valid = false

      raise ATH::Exceptions::SuspiciousOperation.new "Invalid Host: '#{host}'."
    end

    # TODO: Trusted hosts

    host
  end

  # Returns an `HTTP::Params` instance based on this request's form data body.
  def request_data
    @request_data ||= self.parse_request_data
  end

  # Returns the format for this request.
  #
  # First checks if a format was explicitly set via `#request_format=`.
  # Next, will check for the `_format` request `#attributes`, finally falling back on the provided *default*.
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
  # Supports reading from both `ATH::Request::ProxyHeader::FORWARDED_PORT` and `ATH::Request::ProxyHeader::FORWARDED_HOST`, falling back on the `"host"` header, then `#scheme`.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def port : Int32
    if self.from_trusted_proxy? && (host = self.get_trusted_values(ProxyHeader::FORWARDED_PORT)) && !host.empty?
      host = host.first
    elsif self.from_trusted_proxy? && (host = self.get_trusted_values(ProxyHeader::FORWARDED_HOST)) && !host.empty?
      host = host.first
    elsif !(host = @request.headers["host"]?)
      return self.secure? ? 443 : 80
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

    self.secure? ? 443 : 80
  end

  # Returns the scheme of this request.
  def scheme : String
    self.secure? ? "https" : "http"
  end

  # Returns `true` the request was made over HTTPS, otherwise returns `false`.
  #
  # Supports reading from `ATH::Request::ProxyHeader::FORWARDED_PROTO`.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  def secure? : Bool
    if self.from_trusted_proxy? && (proto = self.get_trusted_values(ProxyHeader::FORWARDED_PROTO)) && !proto.empty?
      return proto.first.downcase.in? "https", "on", "ssl", "1"
    end

    # TODO: Possibly have this be based on if server was started with `bind_tls`
    # or if there is eventually some way to access TLS info off `@request`.
    false
  end

  # Returns `true` if this request originated from a trusted proxy.
  #
  # See the [external documentation](/Framework/guides/proxies) for more information.
  def from_trusted_proxy? : Bool
    return false unless trusted_proxies = self.trusted_proxies
    return false unless remote_address = self.remote_address

    ATH::IPUtils.check remote_address, trusted_proxies
  end

  # ameba:disable Metrics/CyclomaticComplexity:
  private def get_trusted_values(type : ProxyHeader) : Array(String)
    cache_key = "#{type}-#{@@trusted_header_set.includes?(type) ? @request.headers[type.header]? : ""}-#{@request.headers[ProxyHeader::FORWARDED.header]?}"

    if result = @trusted_values_cache[cache_key]?
      return result
    end

    client_values = [] of String
    forwarded_values = [] of String

    if @@trusted_header_set.includes?(type) && (header_value = @request.headers[type.header]?)
      header_value.split(',').each do |part|
        client_values << "#{type.forwarded_port? ? "0.0.0.0:" : ""}#{part.strip}"
      end
    end

    if @@trusted_header_set.includes?(ProxyHeader::FORWARDED) && (forwarded_param = type.forwarded_param) && (forwarded = @request.headers[ProxyHeader::FORWARDED.header]?)
      parts = ATH::HeaderUtils.split forwarded, ",;="
      param = type.forwarded_param

      parts.each do |sub_parts|
        # In this particular context compiler gets confused, so lets make it happy by skipping unexpected typed parts, which should never happen.
        next if sub_parts.is_a?(String)
        next if sub_parts.nil?

        unless v = HeaderUtils.combine(sub_parts)[param]?.as?(String?)
          next
        end

        if type.forwarded_port?
          last_colon_idx = v.rindex(':')
          if v.ends_with?(']') || last_colon_idx.nil?
            v = self.secure? ? ":443" : ":80"
          end

          v = "0.0.0.0#{v[last_colon_idx..-1]}"
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

    raise ATH::Exceptions::ConflictingHeaders.new "The request has both a trusted '#{ProxyHeader::FORWARDED.header}' header and a trusted '#{type.header}' header, conflicting with each other. \
      You should either configure your proxy to remove one of them, or configure your project to distrust the offending one."
  end

  private def trusted_proxies : Array(String)?
    return if (trusted_proxies = @@trusted_proxies).empty?
    return unless remote_address = self.remote_address

    trusted_proxies.map do |proxy|
      "REMOTE_ADDRESS" == proxy ? remote_address : proxy
    end
  end

  private def remote_address : String?
    return unless (remote_address = @request.remote_address).is_a? Socket::IPAddress

    remote_address.address
  end

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse @request.body.try(&.gets_to_end) || ""
  end
end
