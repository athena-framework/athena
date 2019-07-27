require "../di"

module Athena::DI
  struct ServiceContainer
    # Mapping of tag name to services with that tag.
    getter tags : Hash(String, Array(String)) = Hash(String, Array(String)).new

    macro finished
      {% begin %}
        # Define a `getter!` in the container for each registered service.
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        {% for service in services %}
          {% for service_ann in service.annotations(Athena::DI::Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.stringify.split("::").last.underscore %}
            private getter {{key.id}} : {{service.id}}
          {% end %}
        {% end %}
      {% end %}
    end

    # Initializes the container.  Auto registering annotated services.
    def initialize
      # Work around for https://github.com/crystal-lang/crystal/issues/7975.
      {{@type}}

      {% begin %}
        # Mapping of registered services to their dependencies.  Used to determine if all service dependencies have been already registered and to detect circular dependencies.
        {% registered_services = {} of String => Array(Nil) %}
        {% service_list = {} of String => Array(Nil) %}

        # Mapping of tag name to services with that tag.
        {% tagged_services = {} of String => Array(String) %}

        # Obtain an array of registered services.
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}

        # Array of services that have no dependencies.
        {% no_dependency_services = services.select { |service| init = service.methods.find(&.name.==("initialize")); !init || init.args.size == 0 } %}

        # Array of services that do not have any tagged services.
        # This includes any service who's arguments are strings and don't start with `!` or are not strings.
        {% services_without_tagged_dependencies = services.select do |service|
             initializer = service.methods.find(&.name.==("initialize"))
             initializer && service.annotations(Athena::DI::Register).all? do |service_ann|
               (0...initializer.args.size).map { |idx| service_ann[idx] }.all? do |arg|
                 (arg.is_a?(StringLiteral) && !arg.starts_with?('!')) || !arg.is_a?(StringLiteral)
               end
             end
           end %}

        # Array of services with tag argument.  Assuming by now all other services would be registered.
        # This includes any services who has at least one argument that is a string and starts with `!`.
        {% services_with_tagged_dependencies = services.select do |service|
             initializer = service.methods.find(&.name.==("initialize"))
             initializer && service.annotations(Athena::DI::Register).any? do |service_ann|
               (0...initializer.args.size).map { |idx| service_ann[idx] }.any? do |arg|
                 (arg.is_a?(StringLiteral) && arg.starts_with?('!'))
               end
             end
           end %}

        # Register the services without dependencies first
        {% for service in no_dependency_services %}
          {% for service_ann in service.annotations(Athena::DI::Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}
            {% registered_services[key] = [] of Nil %}

            {% for tag in tags %}
              {% tagged_services[tag] ? tagged_services[tag] << key : (tagged_services[tag] = [] of String; tagged_services[tag] << key) %}
            {% end %}

            @{{key.id}} = {{service.id}}.new
          {% end %}
        {% end %}

        # Register services that do not have tags next.
        # Iterate until each service's dependencies are satisfied.
        {% for service in services_without_tagged_dependencies %}
          {% initializer = service.methods.find(&.name.==("initialize")) %}
          {% for service_ann in service.annotations(Register) %}
            {% pos_args = (0...initializer.args.size).map { |idx| service_ann[idx] } %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}

            {% service_list[key] = pos_args %}

            {% for tag in tags %}
              {% tagged_services[tag] ? tagged_services[tag] << key : (tagged_services[tag] = [] of String; tagged_services[tag] << key) %}
            {% end %}

            # If the service is registered and one of its dependencies also depends on it.  It's a circular dependency.
            {% if pos_args.any? { |dep| dep.is_a?(StringLiteral) && dep.starts_with?('@') ? service_list[dep[1..-1]] && service_list[dep[1..-1]].includes?("@#{key.id}") : false } %}
              {% raise "Circular dependency detected between '#{service}' and '#{dep[1..-1].camelcase.id}'." %}
            {% end %}

            {% if pos_args.all? { |arg| arg.is_a?(StringLiteral) && arg.starts_with?('@') ? registered_services[arg[1..-1]] : true } %}
              {% registered_services[key] = pos_args %}
              @{{key.id}} = {{service.id}}.new {{(0...initializer.args.size).map { |idx| arg = service_ann[idx]; arg.is_a?(StringLiteral) && arg.starts_with?('@') ? "@#{arg[1..-1].id}".id : arg }.splat}}
            {% else %}
              {% services_without_tagged_dependencies << service %}
            {% end %}
          {% end %}
        {% end %}

       # Lastly register services with tags, assuming their dependencies would have been resolved by now.
        {% for service in services_with_tagged_dependencies %}
          {% initializer = service.methods.find(&.name.==("initialize")) %}
          {% for service_ann in service.annotations(Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}

            @{{key.id}} = {{service.id}}.new {{(0...initializer.args.size).map { |idx| arg = service_ann[idx]; arg.is_a?(StringLiteral) && arg.starts_with?('@') ? "@#{arg[1..-1].id}".id : arg.is_a?(StringLiteral) && arg.starts_with?('!') ? %(#{tagged_services[arg[1..-1]].map { |ts| "@#{ts.id}".id }}).id : arg }.splat}}
          {% end %}
        {% end %}
        @tags = {{tagged_services}} of String => Array(String)
      {% end %}
    end

    # Returns the service with the provided *name*.
    def get(name : String)
      internal_get(name) || raise "No service with the name '#{name}' has been registered."
    end

    # Returns an array of services of the provided *type*.
    def get(type : Service.class)
      get_services_by_type type
    end

    # Returns `true` if a service with the provided *name* has been registered.
    def has(name : String) : Bool
      service_names.includes? name
    end

    # Returns the service of the given *type* and *name*.
    def resolve(type : _, name : String)
      services = get_services_by_type type

      # Return the service if there is only one.
      return services.first if services.size == 1

      # # Otherwise, also use the name to resolve the service.
      if service = internal_get name
        return service
      end

      # Throw an exception if it could not be resolved.
      raise "Could not resolve a service with type '#{type}' and name of '#{name}'."
    end

    # Returns services with the specified *tag*.
    def tagged(tag : String)
      (service_names = @tags[tag]?) ? service_names.map { |service_name| internal_get(service_name).not_nil! } : Array(Athena::DI::Service).new
    end

    # Returns an `Array(Athena::DI::Service)` for services of *type*.
    private def get_services_by_type(type : _)
      {{{@type.instance_vars.reject(&.name.==("tags")).map(&.id).splat}}}.select(&.class.<=(type))
    end

    # Returns a Tuple of registered service names.
    private def service_names
      {{{@type.instance_vars.reject(&.name.==("tags")).map(&.name.stringify).splat}}}
    end

    # Attemps to resolve the provided *name* into a service.
    private def internal_get(name : String) : Athena::DI::Service?
      {% begin %}
        case name
        {% for ivar in @type.instance_vars.reject(&.name.==("tags")) %}
          when {{ivar.name.stringify}} then {{ivar.id}}
        {% end %}
        end
      {% end %}
    end
  end
end
