require "./routing_config"

struct Athena::Routing::Config::Cors
  include ACF::Configuration

  # Indicates whether the request can be made using credentials.
  #
  # Maps to the `access-control-allow-credentials` header.
  getter allow_credentials : Bool = false

  # A white-listed array of valid origins.
  #
  # Can be set to `["*"]` to allow any origin.
  #
  # TODO: Allow `Regex` based origins.
  getter allow_origin : Array(String) = [] of String

  # The header or headers that can be used when making the actual request.
  #
  # Can be set to `["*"]` to allow any headers.
  #
  # maps to the `access-control-allow-headers` header.
  getter allow_headers : Array(String) = [] of String

  # The method or methods allowed when accessing the resource.
  #
  # Maps to the `access-control-allow-methods` header.
  getter allow_methods : Array(String) = [] of String

  # Array of headers that the browser is allowed to read from the response.
  #
  # Maps to the `access-control-expose-headers` header.
  getter expose_headers : Array(String) = [] of String

  # Number of seconds that the results of a preflight request can be cached.
  #
  # Maps to the `access-control-max-age` header.
  getter max_age : Int32 = 0
end

struct Athena::Config::ConfigurationResolver
  def resolve(_type : Athena::Routing::Config::Cors.class) : ART::Config::Cors?
    base.routing.cors
  end
end
