module Athena::DI
  struct ServiceContainer
    # The registered service mapped by name.
    getter services : Hash(String, Definition)

    # Initializes the container.  Auto registering annotated services.
    def initialize
      services_hash = nil
      {% begin %}
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        services_hash = Hash(String, Definition).new nil, {{services.reduce(0) { |acc, s| acc + s.annotations(Athena::DI::Register).size }}}

        {% for service in services %}
          {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% arg_list = !method || method.args.empty? ? [] of Object : (0...method.args.size).map { |idx| service_definition[idx] } %}
            services_hash[{{key}}] = Athena::DI::Definition.new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
          {% end %}
        {% end %}
      {% end %}
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
