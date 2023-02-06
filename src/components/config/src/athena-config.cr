# Convenience alias to make referencing `Athena::Config` types easier.
alias ACF = Athena::Config

# Convenience alias to make referencing `ACF::Annotations` types easier.
alias ACFA = ACF::Annotations

require "./annotation_configurations"
require "./annotations"
require "./base"
require "./parameters"

# A web framework comprised of reusable, independent components.
#
# See [Athena Framework](https://github.com/athena-framework) on Github.
module Athena
  # The name of the environment variable used to determine Athena's current environment.
  ENV_NAME = "ATHENA_ENV"

  # Returns the current environment Athena is in based on `ENV_NAME`.  Defaults to `development` if not defined.
  def self.environment : String
    ENV[ENV_NAME]? || "development"
  end

  # Athena's Config component contains common types for configuring components/features, and managing `ACF::Parameters`.
  #
  # ## Getting Started
  #
  # If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
  # Otherwise, if using it outside of the framework, you will first need to add it as a dependency:
  #
  # ```yaml
  # dependencies:
  #   athena-config:
  #     github: athena-framework/config
  #     version: ~> 0.3.0
  # ```
  #
  # Then run `shards install`, being sure to require it via `require "athena-config"`.
  #
  # From here, checkout the [manual](/architecture/config) for some additional information on how to use it both within and outside of the framework.
  #
  # INFO: DI parameter injection requires the [Athena::DependencyInjection][] component as well.
  module Config
    VERSION = "0.3.1"

    # :nodoc:
    CUSTOM_ANNOTATIONS = [] of Nil

    # Registers a configuration annotation with the provided *name*.
    # Defines a configuration record with the provided *args*, if any, that represents the possible arguments that the annotation accepts.
    # May also be used with a block to add custom methods to the configuration record.
    #
    # ### Example
    #
    # ```
    # # Defines an annotation without any arguments.
    # ACF.configuration_annotation Secure
    #
    # # Defines annotation with a required and optional argument.
    # # The default value will be used if that key isn't supplied in the annotation.
    # ACF.configuration_annotation SomeAnn, id : Int32, debug : Bool = true
    #
    # # A block can be used to define custom methods on the configuration object.
    # ACF.configuration_annotation CustomAnn, first_name : String, last_name : String do
    #   def name : String
    #     "#{@first_name} #{@last_name}"
    #   end
    # end
    # ```
    #
    # NOTE: The logic to actually do the resolution of the annotations must be handled in the owning shard.
    # `Athena::Config` only defines the common logic that each implementation can use.
    # See `ACF::AnnotationConfigurations` for more information.
    macro configuration_annotation(name, *args, &)
      annotation {{name.id}}; end

      # :nodoc:
      record {{name.id}}Configuration < ACF::AnnotationConfigurations::ConfigurationBase{% unless args.empty? %}, {{*args}}{% end %} do
        {{yield}}
      end

      {% CUSTOM_ANNOTATIONS << name %}
    end

    # Returns the configured `ACF::Base` instance.
    # The instance is a lazily initialized singleton.
    #
    # `ACF.load_configuration` may be redefined to change _how_ the configuration object is provided; e.g. create it from a `YAML` or `JSON` configuration file.
    # See the [external documentation](/architecture/config/#configuration) for more information.
    class_getter config : ACF::Base { ACF.load_configuration }

    # Returns the configured `ACF::Parameters` instance.
    # The instance is a lazily initialized singleton.
    #
    # `ACF.load_parameters` may be redefined to change _how_ the parameters object is provided; e.g. create it from a `YAML` or `JSON` configuration file.
    # See the [external documentation](/architecture/config/#parameters) for more information.
    class_getter parameters : ACF::Parameters { ACF.load_parameters }

    # By default return an empty configuration type.
    protected def self.load_configuration : ACF::Base
      ACF::Base.new
    end

    # By default return an empty parameters type.
    protected def self.load_parameters : ACF::Parameters
      ACF::Parameters.new
    end
  end
end
