require "CrSerializer"
require "./custom_settings"
require "./routing_config"

module Athena
  # Returns the current Athena environment.  Defaults to development if no ENV variable was set.
  def self.environment : String
    ENV["ATHENA_ENV"] ||= "development"
  end

  # Returns an `Athena::Config::Config` object for the current environment from config file located at *config_path*.
  def self.config(config_path : String = "athena.yml") : Athena::Config::Config
    Athena::Config::Environments.from_yaml(File.read config_path).environments[self.environment]
  end

  # Wrapper for the `athena.yml` config file.
  module Config
    # Represents each environment and its associated `Athena::Config::Config` object.
    struct Environments
      include CrSerializer(YAML)

      # :nodoc:
      def initialize; end

      # Hash mapping environment name to a config object.
      getter environments : Hash(String, Athena::Config::Config) = {"development" => Athena::Config::Config.new}

      # :nodoc:
      def to_yaml(builder : YAML::Nodes::Builder, serialization_groups : Array(String), expand : Array(String))
        builder.mapping do
          builder.scalar "environments"
          builder.mapping do
            builder.scalar "development", anchor: "development", reference: "development"
            @environments["development"].to_yaml builder, serialization_groups, expand

            builder.scalar "test", anchor: "test"
            builder.mapping do
              builder.scalar "<<"
              builder.scalar "", reference: "development"
            end

            builder.scalar "production", anchor: "production"
            builder.mapping do
              builder.scalar "<<"
              builder.scalar "", reference: "development"
            end
          end
        end
      end
    end

    # Global config object for Athena.
    struct Config
      include CrSerializer(YAML)

      # :nodoc:
      def initialize; end

      # Config properties related to `Athena::Routing` module.
      getter routing : RoutingConfig = Athena::Config::RoutingConfig.new

      # Config properties defined by the user.
      @[CrSerializer::Options(expose: false)]
      @custom_settings : CustomSettings? = nil

      # Config properties defined by the user.
      def custom_settings : CustomSettings
        @custom_settings.not_nil!
      end
    end
  end
end
