module Athena::DI
  # :nodoc:
  module AbstractServiceDefinition; end

  # :nodoc:
  private record ServiceDefinition(ServiceKlass, ServiceArgs, AnnotationArgs), annotation_args : AnnotationArgs, tags : Array(String) do
    include AbstractServiceDefinition

    def construct_service(services : Hash(String, Athena::DI::Service)) : ServiceKlass
      ServiceKlass.new *ServiceArgs.from get_args(services)
    end

    def resolved?(services : Hash(String, Athena::DI::Service)) : Bool
      annotation_args.all? { |a| a.is_a?(String) && a.starts_with?('@') ? services.has_key? a.lchop('@') : true }
    end

    private def get_args(services : Hash(String, Athena::DI::Service))
      annotation_args.map { |a| a.is_a?(String) && a.starts_with?('@') ? services[a.lchop('@')] : a }
    end
  end

  struct ServiceContainer
    # The registered service mapped by name.
    getter services : Hash(String, Athena::DI::Service) = Hash(String, Athena::DI::Service).new

    # Initializes the container.  Auto registering annotated services.
    def initialize
      service_definitions = {} of String => AbstractServiceDefinition
      {% begin %}
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        {% registered_services = [] of String %}
        {% service_definitions = {} of String => AbstractServiceDefinition %}

        # Next iterate over services that have other services as dependencies.  If their dependencies have been resolved in the last step, register them.  Otherwise add them to be resolved later.
        {% for service in services %}          
          {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% if !method || method.args.size == 0 %}
              @services[{{key}}] = {{service.id}}.new
            {% else %}
              {% service_args = (0...method.args.size).map { |idx| service_definition[idx] } %}
              {% service_definitions[key] = "ServiceDefinition(#{service.id}, Tuple(#{method.args.map(&.restriction).splat}), typeof(#{service_args})).new(#{service_args}, #{tags} of String)".id %}
            {% end %}
          {% end %}
        {% end %}
        service_definitions = {{service_definitions}} of String => AbstractServiceDefinition
      {% end %}

      # Resolve services with tags last to make sure required services have been registered
      until service_definitions.empty?
        service_definitions.each do |name, service_definition|
          if service_definition.resolved?(@services)
            @services[name] = service_definition.construct_service(@services)
            service_definitions.delete name
          else
            # Check for circular dependencies
            service_args = service_definition.annotation_args
            circ_dep = service_args.find do |s_arg|
              if s_arg.is_a?(String) && s_arg.starts_with?('@')
                if service = service_definitions[s_arg.lchop('@')]?
                  service.annotation_args.includes?("@#{name}")
                else
                  false
                end
              else
                false
              end
            end

            raise "Circular dependency detected between #{name} and #{circ_dep.lchop('@')}." if circ_dep && circ_dep.is_a?(String)
          end
        end
      end
    end

    # Returns the service with the provided *name*.
    def get(name : String) : Athena::DI::Service
      (s = @services[name]?) ? s : raise "No service with the name '#{name}' has been registered."
    end

    # Returns an array of services of the provided *type*.
    def get(type : Service.class) : Array(Athena::DI::Service)
      get_services_by_type(type)
    end

    # Returns the service of the given *type* and *name*.
    def resolve(type, name : String) : Athena::DI::Service
      services = get_services_by_type type

      # Return the service if there is only one.
      return services.first if services.size == 1

      # Otherwise, also use the name to resolve the service.
      services.each do |s|
        return s if name == @services.key_for s
      end

      # Throw an exception if it could not be resolved.
      raise "Could not resolve a service with type '#{type}' and name of '#{name}'."
    end

    # # Returns services with the specified *tag*.
    def tagged(tag : String) : Array(Athena::DI::Service)
      (services = @tags[tag]?) ? services.map { |service| @services[service] } : Array(Athena::DI::Service).new
    end

    # Returns an `Array(Athena::DI::Service)` for services of *type*.
    private def get_services_by_type(type) : Array(Athena::DI::Service)
      @services.values.select(&.class.<=(type))
    end
  end
end
