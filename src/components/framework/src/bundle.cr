@[Athena::Framework::Annotations::Bundle("framework")]
# :nodoc:
struct Athena::Framework::Bundle < Athena::Framework::AbstractBundle
  PASSES = [
    {Athena::Framework::Console::CompilerPasses::RegisterCommands, :before_removing, nil},
    {Athena::Framework::EventDispatcher::CompilerPasses::RegisterEventListenersPass, :before_removing, nil},
  ]

  # Represents the possible configuration properties, including their name, type, default, and documentation.
  module Schema
    include ADI::Extension::Schema

    property default_locale : String = "en"

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
