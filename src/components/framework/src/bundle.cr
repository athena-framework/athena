@[Athena::Framework::Annotations::Bundle("framework")]
struct Athena::Framework::Bundle < Athena::Framework::AbstractBundle
  PASSES = [
    {Athena::Framework::CompilerPasses::MakeControllerServicesPublicPass, nil, nil},
    {Athena::Framework::Console::CompilerPasses::RegisterCommands, :before_removing, nil},
    {Athena::Framework::EventDispatcher::CompilerPasses::RegisterEventListenersPass, :before_removing, nil},
  ]

  # Represents the possible configuration properties, including their name, type, default, and documentation.
  module Schema
    include ADI::Extension::Schema

    module FormatListener
      include ADI::Extension::Schema

      property? enabled : Bool = false

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

    # Configured how `ATH::Listeners::CORS` functions.
    # If no configuration is provided, that listener is disabled and will not be invoked at all.
    module Cors
      include ADI::Extension::Schema

      property? enabled : Bool = false

      # CORS defaults that affect all routes globally.
      module Defaults
        include ADI::Extension::Schema

        # Indicates whether the request can be made using credentials.
        #
        # Maps to the access-control-allow-credentials header.
        property? allow_credentials : Bool = false

        # A white-listed array of valid origins. Each origin may be a static String, or a Regex.
        #
        # Can be set to ["*"] to allow any origin.
        property allow_origin : Array(String) = [] of String

        # Array of headers that the browser is allowed to read from the response.
        #
        # Maps to the access-control-expose-headers header.
        property expose_headers : Array(String) = [] of String
      end
    end
  end

  module Extension
    macro included
      macro finished
        {% verbatim do %}

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
