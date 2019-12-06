require "../di"

module Athena::DI
  struct ServiceContainer
    # Mapping of tag name to services with that tag.
    getter tags : Hash(String, Array(String)) = Hash(String, Array(String)).new

    macro finished
      {% begin %}
        # Define a `getter` in the container for each registered service.
        {% for service in Athena::DI::Service.all_includers %}
          {% if (annotations = service.annotations(Athena::DI::Register)) && !annotations.empty? %}
            {% for service_ann in service.annotations(Athena::DI::Register) %}
              {% key = service_ann[:name] ? service_ann[:name] : service.name.split("::").last.underscore %}
              # Only make the getter public if the service is public
              {% if service_ann[:public] != true %} private {% end %}getter {{key.id}} : {{service.id}}
            {% end %}
          {% else %}
            {% raise "#{service.name} includes `ADI::Service` but is not registered.  Did you forget the annotation?" unless service.abstract? %}
          {% end %}
        {% end %}
      {% end %}
    end

    # Initializes the container.  Auto registering annotated services.
    def initialize
      # Work around for https://github.com/crystal-lang/crystal/issues/7975.
      {{@type}}

      {% begin %}
        # List of service names already registered.
        {% registered_services = [] of String %}

        # Mapping of tag name to services with that tag.
        {% tagged_services = {} of String => Array(String) %}

        # Obtain an array of registered services.
        {% services = Athena::DI::Service.all_includers.select { |type| type.annotation(Athena::DI::Register) } %}

        # Array of services that have no dependencies.
        {% no_dependency_services = services.select { |service| init = service.methods.find(&.name.==("initialize")); !init || init.args.size == 0 } %}

        # Array of services that do not have any tagged services.
        # This includes any service who's arguments are strings and don't start with `!` or are not strings.
        {% services_without_tagged_dependencies = services.select do |service|
             initializer = service.methods.find(&.name.==("initialize"))
             initializer && initializer.args.size > 0 && service.annotations(Athena::DI::Register).all? do |service_ann|
               service_ann.args.all? do |arg|
                 (arg.is_a?(StringLiteral) && !arg.starts_with?('!')) || !arg.is_a?(StringLiteral)
               end
             end
           end %}

        # Array of services with tag argument.  Assuming by now all other services would be registered.
        # This includes any services who has at least one argument that is a string and starts with `!`.
        {% services_with_tagged_dependencies = services.select do |service|
             initializer = service.methods.find(&.name.==("initialize"))
             initializer && service.annotations(Athena::DI::Register).any? do |service_ann|
               service_ann.args.any? do |arg|
                 (arg.is_a?(StringLiteral) && arg.starts_with?('!'))
               end
             end
           end %}

        # Register the services without dependencies first
        {% for service in no_dependency_services %}
          {% for service_ann in service.annotations(Athena::DI::Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}
            {% registered_services << key %}

            {% for tag in tags %}
              {% tagged_services[tag] ? tagged_services[tag] << key : (tagged_services[tag] = [] of String; tagged_services[tag] << key) %}
            {% end %}

            @{{key.id}} = {{service.id}}.new
          {% end %}
        {% end %}

        {% for service in services_without_tagged_dependencies %}
          {% for service_ann in service.annotations(Athena::DI::Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}
            {% initializer = service.methods.find(&.name.==("initialize")) %}

            {% for tag in tags %}
              {% tagged_services[tag] ? tagged_services[tag] << key : (tagged_services[tag] = [] of String; tagged_services[tag] << key) %}
            {% end %}

            {% if service_ann.args.all? do |arg|
                    if arg.is_a?(StringLiteral) && arg.starts_with?("@?")
                      true
                    elsif arg.is_a?(StringLiteral) && arg.starts_with?('@')
                      registered_services.includes? arg[1..-1]
                    else
                      true
                    end
                  end %}

              {% registered_services << key %}

              @{{key.id}} =  {{service.id}}.new({{service_ann.args.map_with_index do |arg, idx|
                                                    if arg.is_a?(ArrayLiteral)
                                                      "#{arg.map do |array_arg|
                                                           if array_arg.is_a?(StringLiteral) && array_arg.starts_with?("@?")
                                                             # if there is no service use `nil`.
                                                             services.any? &.<=(initializer.args[idx].restriction.resolve) ? "#{array_arg[2..-1].id}".id : nil
                                                           elsif array_arg.is_a?(StringLiteral) && array_arg.starts_with?('@')
                                                             "#{array_arg[1..-1].id}".id
                                                           else
                                                             array_arg
                                                           end
                                                         end} of Union(#{initializer.args[idx].restriction.resolve.type_vars.splat})".id
                                                    elsif arg.is_a?(StringLiteral) && arg.starts_with?("@?")
                                                      # if there is no service use `nil`.
                                                      services.any? &.<=(initializer.args[idx].restriction.resolve) ? "#{arg[2..-1].id}".id : nil
                                                    elsif arg.is_a?(StringLiteral) && arg.starts_with?('@')
                                                      "#{arg[1..-1].id}".id
                                                    else
                                                      arg
                                                    end
                                                  end.splat}})
            {% else %}
              {% for arg, idx in service_ann.args %}
                {% if arg.is_a?(StringLiteral) && arg.starts_with?("@?") %}
                  # ignore
                {% elsif arg.is_a?(StringLiteral) && arg.starts_with?('@') %}
                  {% raise "Could not resolve dependency '#{arg[1..-1].id}' for service '#{service}'.  Did you forget to include `ADI::Service` or declare it optional?" unless services.any? &.<=(initializer.args[idx].restriction.resolve) %}
                {% end %}
              {% end %}

              {% services_without_tagged_dependencies << service %}
            {% end %}
          {% end %}
        {% end %}


        # Lastly register services with tags, assuming their dependencies would have been resolved by now.
        {% for service in services_with_tagged_dependencies %}
          {% for service_ann in service.annotations(Register) %}
            {% key = service_ann[:name] ? service_ann[:name] : service.name.split("::").last.underscore %}
            {% tags = service_ann[:tags] ? service_ann[:tags] : [] of String %}
            {% registered_services << key %}

              @{{key.id}} =  {{service.id}}.new({{service_ann.args.map_with_index do |arg, idx|
                                                    if arg.is_a?(ArrayLiteral)
                                                      arg.map do |array_arg|
                                                        if array_arg.is_a?(StringLiteral) && array_arg.starts_with?("@?")
                                                          # if there is no service use `nil`.
                                                          services.any? &.<=(initializer.args[idx].restriction.resolve) ? "#{array_arg[2..-1].id}".id : nil
                                                        elsif array_arg.is_a?(StringLiteral) && array_arg.starts_with?('@')
                                                          "#{array_arg[1..-1].id}".id
                                                        else
                                                          array_arg
                                                        end
                                                      end
                                                    elsif arg.is_a?(StringLiteral) && arg.starts_with?("@?")
                                                      # if there is no service use `nil`.
                                                      services.any? &.<=(initializer.args[idx].restriction.resolve) ? "#{arg[2..-1].id}".id : nil
                                                    elsif arg.is_a?(StringLiteral) && arg.starts_with?('@')
                                                      "#{arg[1..-1].id}".id
                                                    elsif arg.is_a?(StringLiteral) && arg.starts_with?('!')
                                                      %(#{tagged_services[arg[1..-1]].map { |ts| "#{ts.id}".id }}).id
                                                    else
                                                      arg
                                                    end
                                                  end.splat}})
          {% end %}
        {% end %}
        @tags = {{tagged_services}} of String => Array(String)
      {% end %}
    end

    # Returns an array of services of the provided *type*.
    def get(type : Service.class)
      get_services_by_type type
    end

    # Returns `true` if a service with the provided *name* has been registered.
    def has?(name : String) : Bool
      service_names.includes? name
    end

    # Returns the service of the given *type* and *name*.
    def resolve(type : _, name : String) : Athena::DI::Service
      services = get_services_by_type type

      # Return the service if there is only one.
      return services.first if services.size == 1

      # # Otherwise, also use the name to resolve the service.
      if (service = internal_get name) && services.includes? service
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
