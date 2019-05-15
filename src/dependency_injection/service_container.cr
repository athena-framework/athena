module Athena::DI
  struct ServiceContainer
    # :nodoc:
    private alias ConstructorArgs = String | Int64 | Float64 | Bool | Nil | Athena::DI::Service | Array(ConstructorArgs) | Hash(ConstructorArgs, ConstructorArgs)

    # :nodoc:
    private abstract struct AbstractUnresolvedService; end

    # :nodoc:
    private record UnresolvedService(T, S) < AbstractUnresolvedService, args : Array(ConstructorArgs), tags : Array(String) = [] of String, arg_types : T.class = T, service_class : S.class = S do
      def get_service(args : Array(ConstructorArgs)) : S
        S.new *T.from args
      end
    end

    # The registered service mapped by name.
    getter services : Hash(String, Definition)

    # Initializes the container.  Auto registering annotated services.
    def initialize
      services_hash = nil
      unresolved_services = Hash(String, AbstractUnresolvedService).new
      {% begin %}
        {% registered_services = [] of String %}
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        services_hash = Hash(String, Definition).new nil, {{services.reduce(0) { |acc, s| acc + s.annotations(Athena::DI::Register).size }}}

        # Services with no initialize method, or one with not args, or no references to other services can just be registered outright.
        {% for service in services.select { |s| method = s.methods.find { |m| m.name == "initialize" }; (!method || method.args.size == 0) || (method && method.args.all? { |arg| !(arg.restriction.resolve <= Athena::DI::Service) }) } %}          
        {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% registered_services << key %}
            {% arg_list = !method || method.args.size == 0 ? [] of Object : (0...method.args.size).map { |idx| service_definition[idx] } %}
            services_hash[{{key}}] = Athena::DI::Definition.new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
          {% end %}
        {% end %}

        # Services with an initialize method that has at least one reference to another service require special logic.
        {% for service in services.select { |s| method = s.methods.find { |m| m.name == "initialize" }; (method && method.args.any? { |arg| (arg.restriction.resolve <= Athena::DI::Service) }) } %}
          {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% service_args = (0...method.args.size).map { |idx| arg = service_definition[idx] } %}
            {% if service_args.all? { |a| a.is_a?(StringLiteral) && a.starts_with?('@') ? registered_services.includes?(a[1..-1]) : true } %}
              {% arg_list = (0...method.args.size).map { |idx| arg = service_definition[idx]; arg.is_a?(StringLiteral) && arg.starts_with?('@') ? "services_hash[#{arg[1..-1]}].service.as(#{method.args[idx].restriction})".id : arg } %}
              {% registered_services << key %}
              services_hash[{{key}}] = Athena::DI::Definition.new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
            {% else %}
              unresolved_services[{{key}}] = UnresolvedService(Tuple({{method.args.map(&.restriction).splat}}), {{service.id}}).new({{service_args}} of ConstructorArgs, {{tags}} of String)
            {% end %}
          {% end %}
        {% end %}
      {% end %}

      # While there are still unresolved service dependencies
      until unresolved_services.empty?
        # iterate over them
        unresolved_services.each do |service_name, missing_service|
          # check if all the required services have been resolved;
          all_dependencies_resolved = missing_service.as(UnresolvedService).args.all? { |a| a.is_a?(String) && a.starts_with?('@') ? services_hash.has_key? a.lchop('@') : true }

          if all_dependencies_resolved
            # if so register the service
            args = missing_service.as(UnresolvedService).args.map { |a| a.is_a?(String) && a.starts_with?('@') ? services_hash[a.lchop('@')].service : a }
            services_hash[service_name] = Athena::DI::Definition.new(service: missing_service.as(UnresolvedService).get_service(args), tags: missing_service.as(UnresolvedService).tags)
            # and delete it from the hash
            unresolved_services.delete service_name
          end
        end
      end
      @services = services_hash
    end

    # Returns the service with the provided *name*.
    def get(name : String) : Athena::DI::Service
      (s = @services[name]?) ? s.service : raise "No service with the name '#{name}' has been registered."
    end

    # Returns an array of services of the provided *type*.
    def get(type : Service.class) : Array(Service)
      get_definitions_for_type(type).map &.service
    end

    # Returns the service of the given *type* and *name*.
    def resolve(type, name : String) : Service
      definitions = get_definitions_for_type type

      # Return the service if there is only one.
      return definitions.first.service if definitions.size == 1

      # Otherwise, also use the name to resolve the service.
      definitions.each do |s|
        return s.service if name == @services.key_for s
      end

      # Throw an exception if it could not be resolved.
      raise "Could not resolve a service with type '#{type}' and name of '#{name}'."
    end

    # Returns services with the specified *tag*.
    def tagged(tag : String) : Array(Service)
      @services.values.select(&.tags.includes?(tag)).map &.service
    end

    # Returns an `Array(Athena::DI::Definition)` for services of *type*.
    private def get_definitions_for_type(type) : Array(Definition)
      definitions = @services.values.select(&.service.class.<=(type))
      raise "No service with type '#{type}' has been registered." if definitions.size.zero?
      definitions
    end
  end
end
