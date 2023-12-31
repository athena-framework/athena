# :nodoc:
module Athena::DependencyInjection::ServiceContainer::RegisterServices
  macro included
    macro finished
      {% verbatim do %}
        # Register each service in the hash along with some related metadata.
        {% for klass in Object.all_subclasses.select &.annotation(ADI::Register) %}
          {% if (annotations = klass.annotations(ADI::Register)) && !annotations.empty? && !klass.abstract? %}
            # Raise a compile time exception if multiple services are based on this type, and not all of them specify a `name`.
            {% if annotations.size > 1 && !annotations.all? &.[:name] %}
              {% klass.raise "Failed to register services for '#{klass}'. Services based on this type must each explicitly provide a name." %}
            {% end %}

            {% for ann in annotations %}
              {% ann = ann %}

              # Use the service name defined within the annotation, otherwise fallback on FQN snake cased
              {% id_key = ann[:name] || klass.name.gsub(/::/, "_").underscore %}
              {% service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify %}

              {% factory = nil %}

              {% if factory_ann = ann[:factory] %}
                {% factory = if factory_ann.is_a? StringLiteral
                               {klass.resolve, factory_ann}
                             elsif factory_ann.is_a? TupleLiteral
                               {factory_ann[0].resolve, factory_ann[1]}
                             end %}

                # Validate the factory method exists and is a class method
                {% if factory %}
                  {% factory_class, factory_method = factory %}

                  {% raise "Failed to register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' is an instance method." if factory_class.instance.has_method? factory_method %}
                  {% raise "Failed to register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' does not exist." unless factory_class.class.has_method? factory_method %}
                {% end %}
              {% end %}

              {%
                initializer = if f = factory
                                (f.first).class.methods.find(&.name.==(f[1]))
                              elsif class_initializer = klass.class.methods.find(&.annotation(ADI::Inject))
                                # Class methods with ADI::Inject should act as a factory.
                                factory = {klass, class_initializer.name.stringify}

                                class_initializer
                              elsif specific_initializer = klass.methods.find(&.annotation(ADI::Inject))
                                specific_initializer
                              else
                                klass.methods.find(&.name.==("initialize"))
                              end

                # If no initializer was resolved, assume it's the default argless constructor.
                initializer_args = (i = initializer) ? i.args : [] of Nil
                parameters = {} of Nil => Nil

                initializer_args.each_with_index do |initializer_arg, idx|
                  default_value = nil
                  value = nil

                  # Set the value of this parameter, but don't mark it as resolved as it could be overridden.
                  if !(dv = initializer_arg.default_value).is_a?(Nop)
                    default_value = value = dv
                  end

                  parameters[initializer_arg.name.id.stringify] = {
                    arg:                  initializer_arg,
                    name:                 initializer_arg.name.stringify,
                    idx:                  idx,
                    internal_name:        initializer_arg.internal_name.stringify,
                    restriction:          initializer_arg.restriction,
                    resolved_restriction: ((r = initializer_arg.restriction).is_a?(Nop) ? nil : r.resolve),
                    default_value:        default_value,
                    value:                value || default_value,
                  }
                end

                SERVICE_HASH[service_id] = {
                  class:             klass.resolve,
                  class_ann:         ann,
                  factory:           factory,
                  shared:            klass.class?,
                  calls:             [] of Nil,
                  configurator:      nil,
                  tags:              {} of Nil => Nil,
                  public:            ann[:public] == true,
                  decorated_service: nil,
                  bindings:          {} of Nil => Nil,
                  generics:          [] of Nil,
                  parameters:        parameters,
                }

                if al = ann[:alias]
                  aliases = al.is_a?(ArrayLiteral) ? al : [al]

                  aliases.each do |a|
                    id_key = a.resolve.name.gsub(/::/, "_").underscore
                    alias_service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify

                    SERVICE_HASH[a.resolve] = {
                      class:      klass.resolve,
                      class_ann:  ann,
                      tags:       {} of Nil => Nil,
                      parameters: parameters,
                      bindings:   {} of Nil => Nil,
                      generics:   [] of Nil,

                      alias_service_id:   alias_service_id,
                      aliased_service_id: service_id,
                      alias:              true,
                    }
                  end
                end
              %}
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
