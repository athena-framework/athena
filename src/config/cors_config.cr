module Athena::Config
  # Config properties related to CORS.
  struct CorsConfig
    include YAML::Serializable

    # :nodoc:
    # TODO Remove after https://github.com/crystal-lang/crystal/issues/7557 is resolved.
    def initialize; end

    # Origin to allow requests from. Can be to set to `*` to allow *all* origins.
    getter allow_origin : String = "https://yourdomain.com"

    # Array of headers that the browser is allowed to read from the response.
    getter expose_headers : Array(String) = [] of String

    # Number of seconds that the results of a preflight request can be cached.
    getter max_age : Int32 = 0

    # Indicates whether or not the response to the request can be exposed when the `credentials` flag is true.
    getter allow_credentials : Bool = false

    # The method or methods allowed when accessing the resource.
    getter allow_methods : Array(String) = [] of String

    # The header or headers that can be used when making the actual request.
    getter allow_headers : Array(String) = [] of String
  end
end
