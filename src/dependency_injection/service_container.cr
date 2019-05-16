module Athena::DI
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

  struct ServiceContainer
    private MAX_ITERATIONS = 100_00

    @@cached_services : Hash(String, Definition)? = nil

    # The registered service mapped by name.
    getter services : Hash(String, Definition) = Hash(String, Definition).new

    # Initializes the container.  Auto registering annotated services.
    def initialize
      # Return the cached version if it is set.
      if cs = @@cached_services
        @services = cs
        return
      end

      unresolved_services = {} of String => AbstractUnresolvedService
      {% begin %}
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        {% registered_services = [] of String %}
        {% unresolved_services = {} of String => AbstractUnresolvedService %}

        # Services with no initialize method, or one with no args, or no references to other services can just be registered outright.
        {% for service in services.select { |s| method = s.methods.find { |m| m.name == "initialize" }; (!method || method.args.size == 0) || (method && method.args.all? { |arg| !(arg.restriction.resolve <= Athena::DI::Service) }) } %}          
        {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% arg_list = !method || method.args.size == 0 ? [] of Object : (0...method.args.size).map { |idx| service_definition[idx] } %}
            {% registered_services << key %}
            @services[{{key}}] = Athena::DI::Definition.new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
          {% end %}
        {% end %}

        # Next iterate over services that have other services as dependencies.  If their dependencies have been resolved in the last step, register them.  Otherwise add them to be resolved later.
        {% for service in services.select { |s| method = s.methods.find { |m| m.name == "initialize" }; (method && method.args.any? { |arg| (arg.restriction.resolve <= Athena::DI::Service) }) } %}
          {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% service_args = !method || method.args.size == 0 ? [] of Object : (0...method.args.size).map { |idx| service_definition[idx] } %}
            {% arg_type = !method || method.args.size == 0 ? "Tuple(Nil)".id : "Tuple(#{method.args.map(&.restriction).splat})".id %}
            {% if service_args.all? { |a| a.is_a?(StringLiteral) && a.starts_with?('@') ? registered_services.includes?(a[1..-1]) : true } %}
              {% arg_list = (0...method.args.size).map { |idx| arg = service_definition[idx]; arg.is_a?(StringLiteral) && arg.starts_with?('@') ? "@services[#{arg[1..-1]}].service.as(#{method.args[idx].restriction})".id : arg } %}
              {% registered_services << key %}
              @services[{{key}}] = Athena::DI::Definition.new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
            {% else %}
              {% unresolved_services[key] = "UnresolvedService(#{arg_type}, #{service.id}).new(#{service_args} of ConstructorArgs, #{tags} of String)".id %}
            {% end %}
          {% end %}
        {% end %}
        unresolved_services = {{unresolved_services}} of String => AbstractUnresolvedService
      {% end %}

      iterations : Int32 = 0
      # While there are still unresolved_services
      until unresolved_services.empty?
        # iterate over each
        unresolved_services.each do |name, unresolved_service|
          # checking if all dependencies are resolved
          all_dependencies_resolved = unresolved_service.as(UnresolvedService).args.all? { |a| a.is_a?(String) && a.starts_with?('@') ? @services.has_key? a.lchop('@') : true }

          # if so register the service
          if all_dependencies_resolved
            args = unresolved_service.as(UnresolvedService).args.map { |a| a.is_a?(String) && a.starts_with?('@') ? @services[a.lchop('@')].service : a }
            @services[name] = Athena::DI::Definition.new(service: unresolved_service.as(UnresolvedService).get_service(args), tags: unresolved_service.as(UnresolvedService).tags)
            # and remove it from the hash
            unresolved_services.delete name
          end
        end
        iterations += 1
        # Raise an exception to avoid an infinite loop.  I can't imagine it taking 100,000 iterations so we'll start there.
        raise "Failed to register all services within 100,000 iterations.  Please file a bug for this." if iterations >= MAX_ITERATIONS
      end
      @@cached_services = @services
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

    private def resolve_dependencies(definition)
    end
  end
end
