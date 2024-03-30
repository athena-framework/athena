# :nodoc:
#
# Automatically registers types with an `ADI::Register` annotation.
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

              {%
                factory = if factory_ann = ann[:factory]
                            if factory_ann.is_a? StringLiteral
                              {klass.resolve, factory_ann}
                            elsif factory_ann.is_a? TupleLiteral
                              {factory_ann[0].resolve, factory_ann[1]}
                            end
                          elsif (class_initializer = klass.class.methods.find(&.annotation(ADI::Inject))) && (class_initializer.name.stringify != "new")
                            # Class methods with ADI::Inject should act as a factory.
                            # But only those not named `"new"`, as that's the default and we can't know about overloads of `initialize` at this point.
                            {klass.resolve, class_initializer.name.stringify}
                          else
                            nil
                          end

                # Validate the factory method exists and is a class method if one was found.
                if factory
                  factory_class, factory_method = factory

                  raise "Failed to register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' is an instance method." if factory_class.instance.has_method? factory_method
                  raise "Failed to register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' does not exist." unless factory_class.class.has_method? factory_method
                end
              %}

              {%
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
                  parameters:        {} of Nil => Nil,
                  aliases:           ann[:alias],
                }
              %}
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
