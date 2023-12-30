class Athena::DependencyInjection::ServiceContainer; end

require "./compiler_passes/*"

# Where the instantiated services live.
#
# If a service is public, a getter based on the service's name as well as its type is defined.  Otherwise, services are only available via constructor DI.
#
# TODO: Reduce the amount of duplication when [this issue](https://github.com/crystal-lang/crystal/pull/9091) is resolved.
class Athena::DependencyInjection::ServiceContainer
  # Define a hash to store services while the container is being built
  # Key is the ID of the service and the value is another hash containing its arguments, type, etc.
  private SERVICE_HASH = {} of Nil => Nil

  # Define a hash to store the service ids for each tag.
  #
  # Tag Name, service_id, array attributes
  # Hash(String, Hash(String, Array(NamedTuple)))
  private TAG_HASH = {} of Nil => Nil

  # :nodoc:
  EXTENSIONS = {} of Nil => Nil

  # :nodoc:
  #
  # Holds the compiler pass configuration, including the type of each pass, and the default order the built-in ones execute in.
  PASS_CONFIG = {
    # Global pre-optimization modules
    # Sets up common concepts so that future passes can leverage them
    before_optimization: {
      100 => [
        RegisterServices,
        AutoConfigure,
        ResolveGenerics,
      ],

      1028 => [
        # Ensure merged configuration is available
        MergeConfigs,
        MergeExtensionConfig,
      ],
    },

    # Prepare the services for usage by resolving arguments, parameters, and ensure validity of each service
    optimization: {
      0 => [
        ResolveParameterPlaceholders,
        ApplyBindings,
        AutoWire,
        ResolveValues,
        ValidateArguments,
      ],
    },

    # Determine what could be removed?
    before_removing: {
      0 => [] of Nil,
    },

    # Cleanup the container, removing unused services and such
    removing: {
      0 => [] of Nil,
    },

    # Codegen things that create types/methods within the container instance, such as the getters for each service
    after_removing: {
      -100 => [
        DefineGetters,
      ],
    },
  }

  macro finished
    {%
      passes = [] of Nil

      PASS_CONFIG.keys.each do |type|
        (p = PASS_CONFIG[type]).keys.sort_by { |tk| -tk }.each do |k|
          p[k].each do |pass|
            passes << pass
          end
        end
      end
    %}

    {% for pass in passes %}
      include {{pass.id}}
    {% end %}
  end
end
