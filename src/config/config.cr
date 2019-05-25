require "CrSerializer"
require "./custom_settings"
require "./routing_config"

module Athena
  # Returns an `Athena::Config::Config` object for the config file located at *config_path*.
  def self.config(config_path : String = "athena.yml") : Athena::Config::Config
    Athena::Config::Config.from_yaml File.read config_path
  end

  # Wrapper for the `athena.yml` config file.
  module Config
    # Global config object for Athena.
    struct Config
      include CrSerializer(YAML)

      # :nodoc:
      def initialize; end

      # The environment of the configuration.
      getter environment : String = "development"

      # Config properties related to `Athena::Routing` module.
      getter routing : RoutingConfig = Athena::Config::RoutingConfig.new

      # Config properties defined by the user.
      @custom_settings : CustomSettings? = nil

      # Config properties defined by the user.
      def custom_settings : CustomSettings
        @custom_settings.not_nil!
      end
    end
  end
end
