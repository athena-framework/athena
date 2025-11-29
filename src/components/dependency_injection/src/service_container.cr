class Athena::DependencyInjection::ServiceContainer; end

require "./compiler_passes/*"

# Where the instantiated services live.
#
# If a service is public, a getter based on the service's name as well as its type is defined.  Otherwise, services are only available via constructor DI.
#
# TODO: Reduce the amount of duplication when [this issue](https://github.com/crystal-lang/crystal/pull/9091) is resolved.
class Athena::DependencyInjection::ServiceContainer
  # :nodoc:
  #
  # Define a hash to store services while the container is being built
  # Key is the ID of the service and the value is another hash containing its arguments, type, etc.
  SERVICE_HASH = {} of Nil => Nil

  # :nodoc:
  #
  # Maps services to their aliases
  #
  # Hash(String, NamedTuple(id: String, public: Bool))
  ALIASES = {} of Nil => Nil

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
      1028 => [
        # Ensure merged configuration is available
        MergeConfigs,
        MergeExtensionConfig,
      ],

      100 => [
        NormalizeDefinitions,
        RegisterServices,
        ProcessAliases,
        ProcessAutoconfigureAnnotations,
        ProcessParameters,
        ValidateGenerics,
      ],
    },

    # Prepare the services for usage by resolving arguments, parameters, and ensure validity of each service
    optimization: {
      0 => [
        ResolveParameterPlaceholders,
        ProcessBindings,
        ProcessAnnotationBindings,
        AutoWire,
        ResolveTaggedIterators,
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

  struct Bag
    private abstract struct Param
      abstract def value
    end

    private record Parameter(T) < Param, value : T

    @parameters : Hash(String, Param) = Hash(String, Param).new

    def has?(name : String) : Bool
      @parameters.has_key? name
    end

    # Returns the value of the parameter with the provided *name* if it exists, otherwise `nil`.
    def get?(name : String)
      @parameters[name]?.try &.value
    end

    # Returns the value of the parameter with the provided *name* casted to the provided *type* if it exists, otherwise `nil`.
    def get?(name : String, type : T?.class) : T? forall T
      self.get?(name).as? T?
    end

    # Returns the value of the parameter with the provided *name*.
    #
    # Raises a `KeyError` if no parameter with that name exists.
    def get(name : String)
      @parameters.fetch(name) { raise KeyError.new "No parameter exists with the name '#{name}'." }.value
    end

    # Returns the value of the parameter with the provided *name*, casted to the provided *type*.
    #
    # Raises a `KeyError` if no parameter with that name exists.
    def get(name : String, type : T.class) : T forall T
      self.get(name).as T
    end

    def set(name : String, value : T) forall T
      self.set name, value, T
    end

    def set(name : String, value : T, type : T.class) forall T
      @parameters[name] = Parameter(T).new value
      value
    end

    def remove(name : String) : Nil
      @parameters.delete name
    end
  end

  @@env_resolving = Set(String).new
  @@env_cache = Bag.new

  module ENVVariableProcessorInterface
    abstract def get_env(prefix : String, name : String, type : _.class)
  end

  struct ENVVariableProcessor
    include ENVVariableProcessorInterface

    def get_env(prefix : String, name : String, type : Int32.class) : Int32
      raise "No ENV: #{name}" unless env = ENV[name]?
      p({prefix, name})

      env.to_i
    end

    def get_env(prefix : String, name : String, type : String.class) : String
      raise "No ENV: #{name}" unless env = ENV[name]?
      p({prefix, name})

      env.to_s
    end
  end

  def get_env(name : String, type : T.class) : T forall T
    if @@env_resolving.includes?(env_name = "env(#{name})")
      raise "Circular Reference"
    end

    if @@env_cache.has? name
      return @@env_cache.get name, T
    end

    processor = ENVVariableProcessor.new

    prefix, local_name = if name.includes? ':'
                           name.split ':', 2
                         else
                           {"string", name}
                         end

    @@env_resolving.add env_name
    begin
      @@env_cache.set name, processor.get_env prefix, local_name, T
    ensure
      @@env_resolving.delete env_name
    end
  end
end
