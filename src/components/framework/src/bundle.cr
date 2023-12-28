module Athena::Framework
  # :nodoc:
  abstract struct AbstractBundle
    PASSES = [] of Nil
  end

  # :nodoc:
  @[Athena::Framework::Annotations::Bundle("framework")]
  struct Bundle < AbstractBundle
    # Represents the possible configuration properties, including their name, type, default, and documentation.
    module Schema
      include ADI::Extension::Schema

      # Configured how `ATH::Listeners::CORS` functions.
      # If no configuration is provided, that listener is disabled and will not be invoked at all.
      module Cors
        include ADI::Extension::Schema

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
  end

  macro register_bundle(bundle)
    {%
      bundle.raise "Must be a child of 'ATH::AbstractBundle'." unless bundle <= AbstractBundle

      ann = bundle.annotation Bundle

      bundle.raise "Unable to determine extension name." unless (name = ann[0] || ann["name"])
    %}

    ADI.register_extension {{name}}, "::#{bundle}::Schema".id
  end

  macro configure(config)
    ADI.configure({{config}})
  end
end
