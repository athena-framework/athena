module Athena::DI
  struct ServiceContainer
    # The registered service mapped by name.
    getter services : Hash(String, ServiceDefinition)

    # Initalizes the container.  Auto registering annotated services.
    def initialize
      services_hash = nil
      {% begin %}
        {% services = Athena::DI::StructService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } + Athena::DI::ClassService.all_subclasses.select { |klass| klass.annotation(Athena::DI::Register) } %}
        services_hash = Hash(String, ServiceDefinition).new nil, {{services.reduce(0) { |acc, s| acc + s.annotations(Athena::DI::Register).size }}}

        {% for service in services %}
          {% method = service.methods.find { |m| m.name == "initialize" } %}
          {% for service_definition in service.annotations(Athena::DI::Register) %}
            {% key = service_definition[:name] ? service_definition[:name] : service.name.stringify.split("::").last.underscore %}
            {% tags = service_definition[:tags] ? service_definition[:tags] : "[]".id %}
            {% arg_list = !method || method.args.empty? ? [] of Object : 0...method.args.size.map { |idx| service_definition[idx] } %}
            services_hash[{{key}}] = Athena::DI::Definition({{service.id}}).new(service: {{service.id}}.new({{arg_list.splat}}), tags: {{tags}} of String)
          {% end %}
        {% end %}
      {% end %}
      @services = services_hash
    end

    # Returns the service with the proided *name*.
    def get(name : String) : Athena::DI::Service
      @services[name].service
    end

    # Returns the service of the given *type* and *name*.
    def resolve(type_restriction : S, name : String) forall S
      # if type_restriction <= Array
      #   pp @services.values.select { |s| type_restriction <= s.service.class }
      #   return Array(FeedPartner).new
      # end

      # Attempt to resolve the service based on the type
      services_for_type = @services.values.select &.service_class.==(type_restriction)

      # Raise if there was not one defined
      raise "No service with type '#{type_restriction}' has been registered." if services_for_type.size.zero?

      # return the service if there is only one
      return services_for_type.first.service if services_for_type.size == 1

      # otherwise also use the name to resolve the service
      services_for_type.each do |s|
        return s.service if name == @services.key_for s
      end

      # finally throw an exception if it could not be resolved
      raise "Could not resolve a service with type '#{type_restriction}' and name of '#{name}'."
    end

    # Returns services
    def tagged(tag : String) : Array(Athena::DI::Service)
      @services.values.select(&.tags.includes?(tag)).map(&.service)
    end
  end
end
