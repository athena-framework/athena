@[Athena::Framework::Annotations::Bundle("framework")]
struct Athena::Framework::Bundle < Athena::Framework::AbstractBundle
  # :nodoc:
  PASSES = [
    {Athena::Framework::CompilerPasses::MakeControllerServicesPublicPass, nil, nil},
    {Athena::Framework::Console::CompilerPasses::RegisterCommands, :before_removing, nil},
    {Athena::Framework::EventDispatcher::CompilerPasses::RegisterEventListenersPass, :before_removing, nil},
  ]

  # Represents the possible configuration properties, including their name, type, default, and documentation.
  module Schema
    include ADI::Extension::Schema

    # Configuration related to the `ATH::Listeners::Format` listener.
    #
    # If enabled, the rules are used to determine the best format for the current request based on its
    # [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) header.
    #
    # `ATH::Request::FORMATS` is used to map the request's `MIME` type to its format.
    module FormatListener
      include ADI::Extension::Schema

      # If `false`, the format listener will be disabled and not included in the resulting binary.
      property enabled : Bool = false

      # The rules used to determine the best format.
      # Rules should be defined in priority order, with the highest priority having index 0.
      #
      # ### Example
      #
      # ```
      # ADI.configure({
      #   framework: {
      #     format_listener: {
      #       enabled: true,
      #       rules:   [
      #         {priorities: ["json", "xml"], host: "api.example.com", fallback_format: "json"},
      #         {path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false},
      #         {path: /^\/admin/, priorities: ["xml", "html"]},
      #         {priorities: ["text/html", "*/*"], fallback_format: "html"},
      #       ],
      #     },
      #   },
      # })
      # ```
      #
      # Assuming an `accept` header with the value `text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8,application/json`,
      # a request made to `/foo` from the `api.example.com` hostname; the request format would be `json`.
      # If the request was not made from that hostname; the request format would be `html`.
      # The rules can be as complex or as simple as needed depending on the use case of your application.
      #
      # ---
      # >>path: Use this rules configuration if the request's path matches the regex.
      # >>host: Use this rules configuration if the request's hostname matches the regex.
      # >>methods: Use this rules configuration if the request's method is one of these configured methods.
      # >>priorities: Defines the order of media types the application prefers. If a format is provided instead of a media type,
      # the format is converted into a list of media types matching the format.
      # >>fallback_format: If `nil` and the `path`, `host`, or `methods` did not match the current request, skip this rule and try the next one.
      # If set to a format string, use that format. If `false`, return a `406` instead of considering the next rule.
      # >>stop: If `true`, disables the format listener for this and any following rules.
      # Can be used as a way to enable the listener on a subset of routes within the application.
      # >>prefer_extension: Determines if the `accept` header, or route path `_format` parameter takes precedence.
      # For example, say there is a routed defined as `/foo.{_format}`. When `false`, the format from `_format` placeholder is checked last against the defined `priorities`.
      # Whereas if `true`, it would be checked first.
      # ---
      array_of rules,
        path : Regex? = nil,
        host : Regex? = nil,
        methods : Array(String)? = nil,
        priorities : Array(String)? = nil,
        fallback_format : String | Bool | Nil = "json",
        stop : Bool = false,
        prefer_extension : Bool = true
    end

    # Configures how `ATH::Listeners::CORS` functions.
    # If no configuration is provided, that listener is disabled and will not be invoked at all.
    module Cors
      include ADI::Extension::Schema

      property enabled : Bool = false

      # CORS defaults that affect all routes globally.
      module Defaults
        include ADI::Extension::Schema

        # Indicates whether the request can be made using credentials.
        #
        # Maps to the access-control-allow-credentials header.
        property allow_credentials : Bool = false

        # A white-listed array of valid origins. Each origin may be a static String, or a Regex.
        #
        # Can be set to ["*"] to allow any origin.
        property allow_origin : Array(String | Regex) = [] of String | Regex

        # The header or headers that can be used when making the actual request.
        #
        # Can be set to `["*"]` to allow any headers.
        #
        # maps to the `access-control-allow-headers` header.
        property allow_headers : Array(String) = [] of String

        # Array of headers that the browser is allowed to read from the response.
        #
        # Maps to the access-control-expose-headers header.
        property expose_headers : Array(String) = [] of String

        # The method(s) allowed when accessing the resource.
        #
        # Maps to the `access-control-allow-methods` header.
        # Defaults to the [CORS-safelisted methods](https://fetch.spec.whatwg.org/#cors-safelisted-method).
        property allow_methods : Array(String) = ATH::Listeners::CORS::SAFELISTED_METHODS

        # Number of seconds that the results of a preflight request can be cached.
        #
        # Maps to the `access-control-max-age header`.
        property max_age : Int32 = 0
      end
    end

    module Router
      include ADI::Extension::Schema

      # The default URI used to generate URLs in non-HTTP contexts.
      # See the [Getting Started](/getting_started/routing/#in-commands) docs for more information.
      property default_uri : String? = nil
    end

    module ViewHandler
      include ADI::Extension::Schema

      # If `nil` values should be serialized.
      property emit_nil : Bool = false

      # The `HTTP::Status` used when there is no response content.
      property empty_content_status : HTTP::Status = :no_content

      # The `HTTP::Status` used when validations fail.
      #
      # Currently not used. Included for future work.
      property failed_validation_status : HTTP::Status = :unprocessable_entity
    end
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          # Built-in parameters
          {%
            debug = CONFIG["parameters"]["framework.debug"]

            # If no debug parameter was already configured, try and determine an appropriate value:
            # * true if configured explicitly via ENV var
            # * true if env ENV var is present and not production
            # * true if not compiled with --release
            #
            # This should default to `false`, except explicitly set otherwise
            if debug.nil?
              release_flag = flag?(:release)
              debug_env = env("ATHENA_DEBUG") == "true"
              non_prod_env = env("ATHENA_ENV") != "production"

              CONFIG["parameters"]["framework.debug"] = debug_env || non_prod_env || !flag?(:release)
            end
          %}

          # CORS Listener
          {%
            cfg = CONFIG["framework"]["cors"]

            if cfg["enabled"]
              # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers
              if cfg["defaults"]["allow_credentials"] && cfg["defaults"]["expose_headers"].includes? "*"
                cfg["defaults"]["expose_headers"].raise "'expose_headers' cannot contain a wildcard ('*') when 'allow_credentials' is 'true'."
              end

              # TODO: Support multiple paths
              config = <<-CRYSTAL
                ATH::Listeners::CORS::Config.new(
                  allow_credentials: #{cfg["defaults"]["allow_credentials"]},
                  allow_origin: #{cfg["defaults"]["allow_origin"]},
                  allow_headers: #{cfg["defaults"]["allow_headers"]},
                  allow_methods: #{cfg["defaults"]["allow_methods"]},
                  expose_headers: #{cfg["defaults"]["expose_headers"]},
                  max_age: #{cfg["defaults"]["max_age"]}
                )
              CRYSTAL

              SERVICE_HASH["athena_framework_listeners_cors"] = {
                class:      ATH::Listeners::CORS,
                tags:       {} of Nil => Nil,
                bindings:   {} of Nil => Nil,
                generics:   [] of Nil,
                public:     false,
                parameters: {
                  # TODO: Consider having some other service responsible for resolving the config obj
                  config: {value: config.id, name: "config"},
                },
              }
            end
          %}

          # Format Listener
          {%
            cfg = CONFIG["framework"]["format_listener"]

            if cfg["enabled"] && !cfg["rules"].empty?
              # pp "Yup"
            end
          %}
        {% end %}
      end
    end
  end
end
