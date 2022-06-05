module Athena::DependencyInjection::PreArgumentsCompilerPass
end

module Athena::DependencyInjection::PostArgumentsCompilerPass
end

# Where the instantiated services live.
#
# If a service is public, a getter based on the service's name as well as its type is defined.  Otherwise, services are only available via constructor DI.
#
# TODO: Reduce the amount of duplication when [this issue](https://github.com/crystal-lang/crystal/pull/9091) is resolved.
class Athena::DependencyInjection::ServiceContainer
  # Define a hash to store services while the container is being built
  # Key is the ID of the service and the value is another hash containing its arguments, type, etc.
  private SERVICE_HASH = {} of Nil => Nil

  # Define a hash to map alias types to a service ID.
  private ALIAS_HASH = {} of Nil => Nil

  # Define an array to store the IDs of all used services.
  # I.e. that another service depends on, or is public.
  private USED_SERVICE_IDS = [] of Nil

  private LOCATORS = [] of Nil

  private module RegisterServices
    macro included
      macro finished
        {% verbatim do %}
          # Register each service in the hash along with some related metadata.
          {% for service in Object.all_subclasses.select &.annotation(ADI::Register) %}
            {% if (annotations = service.annotations(ADI::Register)) && !annotations.empty? && !service.abstract? %}
              # Raise a compile time exception if multiple services are based on this type, and not all of them specify a `name`.
              {% if annotations.size > 1 && !annotations.all? &.[:name] %}
                {% service.raise "Failed to register services for '#{service}'.  Services based on this type must each explicitly provide a name." %}
              {% end %}

              {% auto_configuration = (key = AUTO_CONFIGURATIONS.keys.find &.>=(service.resolve)) ? AUTO_CONFIGURATIONS[key] : {} of Nil => Nil %}

              {% for ann in annotations %}
                {% ann = ann %}
                # If positional arguments are provided, use them as generic arguments
                {% generics = ann.args %}

                # Use the service name defined within the annotation, otherwise fallback on FQN snake cased
                {% id_key = ann[:name] || service.name.gsub(/::/, "_").underscore %}
                {% service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify %}
                {% tags = [] of Nil %}

                {% if !service.type_vars.empty? && (ann && !ann[:name]) %}
                  {% service.raise "Failed to register services for '#{service}'.  Generic services must explicitly provide a name." %}
                {% end %}

                {% if !service.type_vars.empty? && generics.empty? %}
                  {% service.raise "Failed to register service '#{service_id.id}'.  Generic services must provide the types to use via the 'generics' field." %}
                {% end %}

                {% if service.type_vars.size != generics.size %}
                  {% service.raise "Failed to register service '#{service_id.id}'.  Expected #{service.type_vars.size} generics types got #{generics.size}." %}
                {% end %}

                {% if ann[:alias] != nil %}
                  {% ALIAS_HASH[ann[:alias].resolve] = service_id %}
                {% end %}

                {% if (ann_tags = ann[:tags]) || (ann_tags = auto_configuration[:tags]) %}
                  {% ann.raise "Failed to register service `#{service_id.id}`.  Tags must be an ArrayLiteral or TupleLiteral, not #{ann_tags.class_name.id}." unless ann_tags.is_a? ArrayLiteral %}
                  {% tags = ann_tags.map do |tag|
                       if tag.is_a? StringLiteral
                         {name: tag}
                       elsif tag.is_a? Path
                         {name: tag.resolve}
                       elsif tag.is_a? NamedTupleLiteral
                         tag.raise "Failed to register service `#{service_id.id}`.  All tags must have a name." unless tag[:name]

                         # Resolve a constant to its value if used as a tag name
                         if tag[:name].is_a? Path
                           tag[:name] = tag[:name].resolve
                         end

                         tag
                       else
                         tag.raise "Failed to register service `#{service_id.id}`.  A tag must be a StringLiteral or NamedTupleLiteral not #{tag.class_name.id}."
                       end
                     end %}
                {% end %}

                {% factory = nil %}

                {% if factory_ann = ann[:factory] %}
                  {% factory = if factory_ann.is_a? StringLiteral
                                 {service.resolve, factory_ann}
                               elsif factory_ann.is_a? TupleLiteral
                                 {factory_ann[0].resolve, factory_ann[1]}
                               end %}

                  # Validate the factory method exists and is a class method
                  {% if factory %}
                    {% klass = factory[0] %}
                    {% method = factory[1] %}

                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{klass}` is an instance method." if klass.instance.has_method? method %}
                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{klass}` does not exist." unless klass.class.has_method? method %}
                  {% end %}
                {% end %}

                {%
                  SERVICE_HASH[service_id] = {
                    generics:           generics,
                    public:             ann[:public] != nil ? ann[:public] : (auto_configuration[:public] != nil ? auto_configuration[:public] : false),
                    public_alias:       ann[:public_alias] != nil ? ann[:public_alias] : false,
                    service_annotation: ann,
                    tags:               tags,

                    # If there is a factory set the service to that type so dependencies are resolved against the factory method
                    service:   factory ? factory.first : service.resolve,
                    ivar_type: ann[:type] || service.resolve,
                    factory:   factory,
                  }
                %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end
    end
  end

  private module ResolveArguments
    macro included
      macro finished
        {% verbatim do %}
          # Resolve the arguments for each service
          {% for service_id, metadata in SERVICE_HASH %}
            {% service_ann = metadata[:service_annotation] %}
            {% service = metadata[:service] %}

            # Resolve which method (internal or external) should used to construct the service instance.
            {%
              initializer = if factory = metadata[:factory]
                              service.class.methods.find(&.name.==(factory[1]))
                            elsif class_initializer = service.class.methods.find(&.annotation(ADI::Inject))
                              # Class methods with ADI::Inject should act as a factory.
                              metadata[:factory] = {service, class_initializer.name.stringify}

                              class_initializer
                            elsif instance_initializer = service.methods.find(&.annotation(ADI::Inject))
                              instance_initializer
                            else
                              service.methods.find(&.name.==("initialize"))
                            end
            %}

            # If no initializer was resolved, assume it's the default argless constructor.
            {% initializer_args = (i = initializer) ? i.args : [] of Nil %}

            {%
              arguments = initializer_args.map_with_index do |initializer_arg, idx|
                # Check if an explicit value was passed for this initializer_arg
                if service_ann && service_ann.named_args.keys.includes? "_#{initializer_arg.name}".id
                  named_arg = service_ann.named_args["_#{initializer_arg.name}"]

                  if named_arg.is_a?(ArrayLiteral)
                    # Create a lazy enumerable type for Enumerable arguments that consist of all service references or type nodes
                    # that will lazily resolve each service.
                    if ["Enumerable", "Iterator", "Indexable", "Iterable"].includes?(initializer_arg.restriction.resolve.name(generic_args: false).stringify) && named_arg.all? { |a| v = a.is_a?(Path) ? a.resolve : a; (v.is_a?(StringLiteral) && v.starts_with?('@')) || v.is_a?(Generic) || v.is_a?(TypeNode) }
                      inner_args = named_arg.map do |arr_arg|
                        arr_arg = arr_arg.is_a?(Path) ? arr_arg.resolve : arr_arg

                        if arr_arg.is_a?(StringLiteral) && arr_arg.starts_with?('@')
                          service_name = arr_arg[1..-1]
                          arr_arg.raise "Failed to register service '#{service_id.id}'.  Could not resolve argument '#{arr_arg}' from named argument value '#{named_arg}'." unless SERVICE_HASH[service_name]
                          USED_SERVICE_IDS << service_name.id
                          service_name.id
                        elsif !(r = arr_arg).is_a?(Nop) && r.is_a?(TypeNode) && (type = r.resolve?)
                          resolved_services = [] of Nil

                          # Otherwise resolve possible services based on type
                          SERVICE_HASH.each do |id, s_metadata|
                            if (s_metadata[:service] <= type || (type < ADI::Proxy && s_metadata[:service] <= type.type_vars.first.resolve))
                              resolved_services << id
                            end
                          end

                          if resolved_services.size == 1
                            USED_SERVICE_IDS << resolved_services[0].id
                            resolved_services[0].id
                          else
                            arr_arg.raise "Failed to resolve Enumerable service."
                          end
                        else
                          arr_arg.raise "Failed to register service '#{service_id.id}'.  Arrays more than two levels deep are not currently supported."
                        end
                      end

                      ITERATORS[service_id.camelcase] = inner_args

                      "#{service_id.camelcase.id}Iterator(#{initializer_arg.restriction.resolve.type_vars.splat}, #{inner_args.size}).new(self)".id
                    else
                      inner_args = named_arg.map do |arr_arg|
                        if arr_arg.is_a?(ArrayLiteral)
                          arr_arg.raise "Failed to register service '#{service_id.id}'.  Arrays more than two levels deep are not currently supported."
                        elsif arr_arg.is_a?(StringLiteral) && arr_arg.starts_with?('@')
                          service_name = arr_arg[1..-1]
                          arr_arg.raise "Failed to register service '#{service_id.id}'.  Could not resolve argument '#{initializer_arg}' from named argument value '#{named_arg}'." unless SERVICE_HASH[service_name]
                          USED_SERVICE_IDS << service_name.id
                          service_name.id
                        elsif arr_arg.is_a?(StringLiteral) && arr_arg.starts_with?('%') && arr_arg.ends_with?('%')
                          "ACF.parameters.#{arr_arg[1..-2].id}".id
                        else
                          arr_arg
                        end
                      end

                      %((#{inner_args} of Union(#{initializer_arg.restriction.resolve.type_vars.splat}))).id
                    end
                  elsif named_arg.is_a?(StringLiteral) && named_arg.starts_with?('!')
                    tagged_services = [] of Nil

                    # Build an array of services with the given tag, along with the tag metadata
                    SERVICE_HASH.each do |id, s_metadata|
                      if t = s_metadata[:tags].find &.[:name].==(named_arg[1..-1])
                        USED_SERVICE_IDS << id.id
                        tagged_services << {id.id, t}
                      end
                    end

                    # Sort based on tag priority.  Services without a priority will be last in order of definition
                    tagged_services = tagged_services.sort_by { |item| -(item[1][:priority] || 0) }

                    if initializer_arg.restriction.type_vars.first.resolve < ADI::Proxy
                      tagged_services = tagged_services.map do |ts|
                        {"ADI::Proxy.new(#{ts[1][:name]}, ->#{ts[0]})".id}
                      end
                    end

                    %((#{tagged_services.map(&.first)} of Union(#{initializer_args[idx].restriction.resolve.type_vars.splat}))).id
                  elsif named_arg.is_a?(StringLiteral) && named_arg.starts_with?('%') && named_arg.ends_with?('%')
                    "ACF.parameters.#{named_arg[1..-2].id}".id
                  else
                    named_arg
                  end
                elsif (bindings = BINDINGS[initializer_arg.name.stringify]) && # Check if there are any bindings defined for this argument
                      (
                        (binding = bindings[:typed].find &.[:type].<=(initializer_arg.restriction.resolve)) || # First try resolving it via a typed bindings since they are more specific
                        (binding = bindings[:untyped].first)                                                   # Otherwise fallback on last defined untyped binding (they're pushed in reverse order)
                      )
                  binding_value = binding[:value]

                  if binding_value.is_a?(ArrayLiteral)
                    inner_binding_args = binding_value.map do |arr_arg|
                      if arr_arg.is_a?(ArrayLiteral)
                        arr_arg.raise "Failed to register service '#{service_id.id}'.  Arrays more than two levels deep are not currently supported."
                      elsif arr_arg.is_a?(StringLiteral) && arr_arg.starts_with?('@')
                        service_name = arr_arg[1..-1]
                        raise "Failed to register service '#{service_id.id}'.  Could not resolve argument '#{initializer_arg}' from binding value '#{binding_value}'." unless SERVICE_HASH[service_name]
                        USED_SERVICE_IDS << service_name.id
                        service_name.id
                      else
                        arr_arg
                      end
                    end

                    %((#{inner_binding_args} of Union(#{initializer_arg.restriction.resolve.type_vars.splat}))).id
                  elsif binding_value.is_a?(StringLiteral) && binding_value.starts_with?('!')
                    tagged_services = [] of Nil

                    # Build an array of services with the given tag, along with the tag metadata
                    SERVICE_HASH.each do |id, s_metadata|
                      if t = s_metadata[:tags].find &.[:name].==(binding_value[1..-1])
                        USED_SERVICE_IDS << id.id
                        tagged_services << {id.id, t}
                      end
                    end

                    # Sort based on tag priority.  Services without a priority will be last in order of definition
                    tagged_services = tagged_services.sort_by { |item| -(item[1][:priority] || 0) }

                    if initializer_arg.restriction.type_vars.first.resolve < ADI::Proxy
                      tagged_services = tagged_services.map do |ts|
                        {"ADI::Proxy.new(#{ts[1][:name]}, ->#{ts[0]})".id}
                      end
                    end

                    %((#{tagged_services.map(&.first)} of Union(#{initializer_args[idx].restriction.resolve.type_vars.splat}))).id
                  elsif binding_value.is_a?(StringLiteral) && binding_value.starts_with?('%') && binding_value.ends_with?('%')
                    "ACF.parameters.#{binding_value[1..-2].id}".id
                  else
                    binding_value
                  end
                else
                  resolved_services = [] of Nil

                  # Otherwise resolve possible services based on type
                  SERVICE_HASH.each do |id, s_metadata|
                    if !(r = initializer_arg.restriction).is_a?(Nop) && (type = r.resolve?) &&
                       (
                         s_metadata[:service] <= type ||
                         (type < ADI::Proxy && s_metadata[:service] <= type.type_vars.first.resolve)
                       )
                      resolved_services << id
                    end
                  end

                  # If no services could be resolved
                  if resolved_services.size == 0
                    # Return a default value if any

                    # First check to see if it's a resolvable configuration type.
                    if !(r = initializer_arg.restriction).is_a?(Nop) && (configuration_type = initializer_arg.restriction.types.find(&.resolve.annotation ACFA::Resolvable)) && (configuration_ann = configuration_type.resolve.annotation ACFA::Resolvable)
                      path = configuration_ann[0] || configuration_ann["path"] || configuration_type.raise "Configuration type '#{configuration_type}' has an ACFA::Resolvable annotation but is missing the type's configuration path. It was not provided as the first positional argument nor via the 'path' field."

                      "ACF.config.#{path.id}".id
                    elsif !initializer_arg.default_value.is_a? Nop
                      # Otherwise fallback on a default value, if any
                      initializer_arg.default_value
                    elsif initializer_arg.restriction.resolve.nilable?
                      # including `nil` if thats a possibility
                      nil
                    else
                      # otherwise raise an exception
                      initializer_arg.raise "Failed to auto register service '#{service_id.id}'.  Could not resolve argument '#{initializer_arg}'."
                    end
                  elsif resolved_services.size == 1
                    USED_SERVICE_IDS << resolved_services[0].id

                    # If only one was matched, return it,
                    # using an ADI::Proxy object if thats what the initializer expects.
                    if initializer_arg.restriction.resolve < ADI::Proxy
                      "ADI::Proxy.new(#{resolved_services[0]}, ->#{resolved_services[0].id})".id
                    else
                      resolved_services[0].id
                    end
                  else
                    # Otherwise fallback on the argument's name as well
                    if resolved_service = resolved_services.find(&.==(initializer_arg.name))
                      USED_SERVICE_IDS << resolved_service.id

                      # use an ADI::Proxy object if thats what the initializer expects.
                      if initializer_arg.restriction.resolve < ADI::Proxy
                        "ADI::Proxy.new(#{resolved_service}, ->#{resolved_service.id})".id
                      else
                        USED_SERVICE_IDS << resolved_service.id
                        resolved_service.id
                      end

                      # If no service with that name could be resolved, check the alias map for the restriction
                    elsif aliased_service = ALIAS_HASH[(initializer_arg.restriction.resolve < ADI::Proxy ? initializer_arg.restriction.type_vars.first.resolve : initializer_arg.restriction.resolve)]
                      USED_SERVICE_IDS << aliased_service.id

                      # If one is found returned the aliased service
                      # use an ADI::Proxy object if thats what the initializer expects.
                      if initializer_arg.restriction.resolve < ADI::Proxy
                        "ADI::Proxy.new(#{aliased_service}, ->#{aliased_service.id})".id
                      else
                        aliased_service.id
                      end
                    else
                      # Otherwise raise an exception
                      initializer_arg.raise "Failed to auto register service '#{service_id.id}'.  Could not resolve argument '#{initializer_arg}'."
                    end
                  end
                end
              end
            %}

            {% SERVICE_HASH[service_id][:arguments] = arguments %}
          {% end %}
        {% end %}
      end
    end
  end

  private module RemoveUnusedServices
    macro included
      macro finished
        {% verbatim do %}
      {% SERVICE_HASH.each do |service_id, metadata|
           # Services that are private and not used in other dependencies can safely be removed.
           if metadata[:public] == true || metadata[:public_alias] == true || USED_SERVICE_IDS.includes?(service_id.id)
           else
             SERVICE_HASH[service_id] = nil
           end
         end %}
        {% end %}
      end
    end
  end

  private module DefineLocators
    macro included
      macro finished
        {% verbatim do %}
          {% for locator in LOCATORS %}
            struct ::{{locator[:name].id}}
              def initialize(@container : ADI::ServiceContainer); end

              {% for service_type, service_id in locator[:map] %}
                def get(service : {{service_type}}.class) : {{service_type}}
                  @container.{{service_id.id}}
                end
              {% end %}
              
              def get(service)
                {% begin %}
                  case service
                  {% for service_type, service_id in locator[:map] %}
                    when {{service_type}} then @container.{{service_id.id}}
                  {% end %}
                  else
                    raise "BUG: Couldn't find correct ACON::Command"
                  end
                {% end %}
              end
            end
          {% end %}
        {% end %}
      end
    end
  end

  private module DefineGetters
    macro included
      macro finished
        {% verbatim do %}
          # Define getters for each service, if the service is public, make the getter public and also define a type based getter
          {% for service_id, metadata in SERVICE_HASH %}
            {% if metadata != nil %}
              {% service_name = metadata[:service].is_a?(StringLiteral) ? metadata[:service] : metadata[:service].name(generic_args: false) %}
              {% generics_type = "#{service_name}(#{metadata[:generics].splat})".id %}

              {% service = metadata[:generics].empty? ? metadata[:service] : generics_type %}
              {% ivar_type = metadata[:generics].empty? ? metadata[:ivar_type] : generics_type %}

              {% constructor_service = service %}
              {% constructor_method = "new" %}

              {% if factory = metadata[:factory] %}
                {% constructor_service = factory[0] %}
                {% constructor_method = factory[1] %}
              {% end %}

              {% if metadata[:public] != true %}protected{% end %} getter {{service_id.id}} : {{ivar_type.id}} { {{constructor_service.id}}.{{constructor_method.id}}({{metadata[:arguments].splat}}) }

              {% if metadata[:public] %}
                def get(service : {{service}}.class) : {{service.id}}
                  {{service_id.id}}
                end
              {% end %}
              
              
              
            {% end %}
          {% end %}

          # Define getters for aliased service, if the alias is public, make the getter public and also define a type based getter
          {% for service_type, service_id in ALIAS_HASH %}
            {% metadata = SERVICE_HASH[service_id] %}
            
            {% if metadata != nil %}
              {% service_name = metadata[:service].is_a?(StringLiteral) ? metadata[:service] : metadata[:service].name(generic_args: false) %}
              {% type = metadata[:generics].empty? ? service_name : "#{service_name}(#{metadata[:generics].splat})".id %}

              {% if metadata[:public_alias] != true %}protected{% end %} def {{service_type.name.gsub(/::/, "_").underscore.id}} : {{type}}; {{service_id.id}}; end

              {% if metadata[:public_alias] %}
                def get(service : {{service_type}}.class) : {{service_type}}
                  {{service_id.id}}
                end
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end
    end
  end

  macro finished
    include RegisterServices

    # Hook into container after services are registered, but before arguments are resolved.
    # Can be used to register additional services.

    {% for pass in Athena::DependencyInjection::PreArgumentsCompilerPass.includers %}
      include {{pass.id}}
    {% end %}

    include ResolveArguments

    # Hook into container after arguments are resolved.
    # Can be used to alter arguments of services.

    {% for pass in Athena::DependencyInjection::PostArgumentsCompilerPass.includers %}
      include {{pass.id}}
    {% end %}

    include RemoveUnusedServices
    include DefineGetters
    include DefineLocators
  end
end
