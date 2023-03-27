class Athena::DependencyInjection::ServiceContainer; end

require "./stages/*"

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

  # Args on annotation are like direct named args that apply to that singular service
  # Bindings apply to 0..n services
  # Autowiring apply to 0..n services. Terminal state

  # # Algorithm
  #
  # ## PreOptimization
  # * RegisterServices
  # * ResolveGenerics
  # * Run custom modules
  # * (TODO) Try and support annotation based configurators
  #
  # ## Optimization
  # * Resolve parameter placeholders
  # * Bindings
  # * Autowire
  # * Run custom modules
  #
  # ## Removing
  # * Run custom modules
  # * RemoveUnusedServices
  #
  # ## PostRemoving
  # * DefineGetters

  # TODO: Ability to know if a service's args weren't resolved

  # Determine Value
  #   * DONE explicit param - _id
  #   * DONE default value - = 123
  #   * DONE Binding (Typed and untyped)
  #     * Ann > Global > autoconfigure
  #   * Alias
  #   * Autowire
  #   * Nilable - nil

  # Resolve Value
  #   * DONE %param%
  #   * DONE @service_id
  #   * DONE !tag
  #   * DONE Proxy

  macro finished
    # Global pre-optimization modules
    include RegisterServices
    include Autoconfigure
    include ResolveGenerics
    include RegisterExtensions

    # Custom modules to register new services, explicitly set arguments, or modify them in some other way

    # Global optimization modules that prepare the services for usage
    # Resolve arguments, parameters, and ensure validity of each service
    include ResolveParameterPlaceholders
    include ApplyBindings
    include AutoWire
    include ResolveValues
    include ValidateArguments

    # Custom modules to further modify services

    # Global cleanup services
    # include RemoveUnusedServices

    # Global codegen things that create things within the container instances, such as the getters for each service
    include DefineGetters

    # ?? Custom modules to codegen/cleanup things?
  end
end
