require "./config"

struct Athena::Framework::Config; end

# Configuration options for `ATH::Listeners::CORS`. See `.configure`.
#
# TODO: Allow scoping `CORS` options to specific routes versus applying them to all routes.
@[ACFA::Resolvable("routing.cors")]
struct Athena::Framework::Config::CORS
  # This method should be overridden in order to provide the configuration for `ATH::Listeners::CORS`.
  # See the [external documentation](/architecture/config#configuration) for more details.
  #
  # By default it returns `nil`, which disables the listener.
  #
  # ```
  # # Returns an `ATH::Config::CORS` instance that will determine how the listener functions.
  # def ATH::Config::CORS.configure : ATH::Config::CORS?
  #   new(
  #     allow_credentials: true,
  #     allow_origin: %(https://app.example.com),
  #     expose_headers: %w(X-Transaction-ID X-Some-Custom-Header),
  #   )
  # end
  # ```
  def self.configure : self?
    nil
  end

  # Indicates whether the request can be made using credentials.
  #
  # Maps to the `access-control-allow-credentials` header.
  getter? allow_credentials : Bool

  # A white-listed array of valid origins.
  # Each origin may be a static `String`, or a `Regex`.
  #
  # Can be set to `["*"]` to allow any origin.
  getter allow_origin : Array(String | Regex)

  # The header or headers that can be used when making the actual request.
  #
  # Can be set to `["*"]` to allow any headers.
  #
  # maps to the `access-control-allow-headers` header.
  getter allow_headers : Array(String)

  # The method or methods allowed when accessing the resource.
  #
  # Maps to the `access-control-allow-methods` header.
  # Defaults to the [CORS-safelisted methods](https://fetch.spec.whatwg.org/#cors-safelisted-method).
  getter allow_methods : Array(String)

  # Array of headers that the browser is allowed to read from the response.
  #
  # Maps to the `access-control-expose-headers` header.
  getter expose_headers : Array(String)

  # Number of seconds that the results of a preflight request can be cached.
  #
  # Maps to the `access-control-max-age` header.
  getter max_age : Int32

  # See `.configure`.
  def initialize(
    @allow_credentials : Bool = false,
    allow_origin : Array(String | Regex) = Array(String | Regex).new,
    @allow_headers : Array(String) = [] of String,
    @allow_methods : Array(String) = Athena::Framework::Listeners::CORS::SAFELISTED_METHODS,
    @expose_headers : Array(String) = [] of String,
    @max_age : Int32 = 0
  )
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers
    if @allow_credentials && @expose_headers.includes? "*"
      raise ArgumentError.new "expose_headers cannot contain a wildcard ('*') when allow_credentials is 'true'."
    end

    @allow_origin = allow_origin.map &.as String | Regex
  end
end
