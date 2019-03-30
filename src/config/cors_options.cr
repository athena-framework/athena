module Athena::Config
  # Config properties related to CORS.
  struct CorsOptions
    include CrSerializer

    @[YAML::Field(ignore: true)]
    @default : Bool = false

    # :nodoc:
    def initialize(@default : Bool = false); end

    # Origin to allow requests from. Can be to set to `"*"` to allow *all* origins.
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

    # :nodoc:
    def to_yaml(builder : YAML::Nodes::Builder)
      builder.mapping(anchor: @default ? "defaults" : "") do
        builder.scalar "allow_origin"
        builder.scalar @allow_origin

        builder.scalar "expose_headers"
        builder.sequence do
          @expose_headers.each do |header|
            builder.scalar header
          end
        end

        builder.scalar "max_age"
        builder.scalar @max_age

        builder.scalar "allow_credentials"
        builder.scalar @allow_credentials

        builder.scalar "allow_methods"
        builder.sequence do
          @allow_methods.each do |header|
            builder.scalar header
          end
        end

        builder.scalar "allow_headers"
        builder.sequence do
          @allow_headers.each do |header|
            builder.scalar header
          end
        end
      end
    end
  end
end
