@[Athena::Framework::Annotations::Bundle("framework")]
# :nodoc:
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

      property rules : Array({path: Regex}) = [] of NoReturn
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
        property allow_origin : Array(String | Regex) = [] of String | Regex

        property allow_headers : Array(String) = [] of String

        # Array of headers that the browser is allowed to read from the response.
        #
        # Maps to the access-control-expose-headers header.
        property expose_headers : Array(String) = [] of String
        property allow_methods : Array(String) = ATH::Listeners::CORS::SAFELISTED_METHODS
        property max_age : Int32 = 0
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

          # CORS Listener
          {%
            cfg = CONFIG["framework"]["cors"]

            if cfg["enabled"]
              # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers
              if cfg["defaults"]["allow_credentials"] && cfg["defaults"]["expose_headers"].includes? "*"
                cfg["defaults"]["expose_headers"].raise "expose_headers cannot contain a wildcard ('*') when allow_credentials is 'true'."
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
                public:     true,
                parameters: {
                  config: {value: config.id, name: "config"},
                },
              }
            end

            puts ""
            puts ""
          %}
        {% end %}
      end
    end
  end
end
