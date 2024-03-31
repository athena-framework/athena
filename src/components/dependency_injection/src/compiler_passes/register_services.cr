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
              {% klass.raise "Failed to auto register services for '#{klass}'. Services based on this type must each explicitly provide a name." %}
            {% end %}

            {% for ann in annotations %}
              {% ann = ann %}
              {% klass = klass %}

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

                  raise "Failed to auto register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' is an instance method." if factory_class.instance.has_method? factory_method
                  raise "Failed to auto register service '#{service_id.id}'. Factory method '#{factory_method.id}' within '#{factory_class}' does not exist." unless factory_class.class.has_method? factory_method
                end
              %}

              {%
                definition_tags = {} of Nil => Nil
                tags = ann["tags"] || [] of Nil

                unless tags.is_a? ArrayLiteral
                  ann["tags"].raise "Tags for '#{service_id.id}' must be an 'ArrayLiteral', got '#{tags.class_name.id}'."
                end

                # TODO: Centralize tag handling logic between AutoConfigure and RegisterServices
                tags.each do |tag|
                  name, attributes = if tag.is_a?(StringLiteral)
                                       {tag, {} of Nil => Nil}
                                     elsif tag.is_a?(Path)
                                       {tag.resolve.id.stringify, {} of Nil => Nil}
                                     elsif tag.is_a?(NamedTupleLiteral) || tag.is_a?(HashLiteral)
                                       tag.raise "Failed to auto register service '#{service_id.id}'. All tags must have a name." unless tag[:name]

                                       # Resolve a constant to its value if used as a tag name
                                       if tag["name"].is_a? Path
                                         tag["name"] = tag["name"].resolve
                                       end

                                       attributes = {} of Nil => Nil

                                       # TODO: Replace this with `#delete`...
                                       tag.each do |k, v|
                                         attributes[k.id.stringify] = v unless k.id.stringify == "name"
                                       end

                                       {tag["name"], attributes}
                                     else
                                       tag.raise "Tag '#{tag}' must be a 'StringLiteral' or 'NamedTupleLiteral', got '#{tag.class_name.id}'."
                                     end

                  definition_tags[name] = [] of Nil if definition_tags[name] == nil
                  definition_tags[name] << attributes
                  definition_tags[name] = definition_tags[name].uniq

                  TAG_HASH[name] = [] of Nil if TAG_HASH[name] == nil
                  TAG_HASH[name] << {service_id, attributes}
                  TAG_HASH[name] = TAG_HASH[name].uniq
                end
              %}

              # Generic services are somewhat coupled to the annotation, so do a check here in addition to those in `ResolveGenerics`.
              {%
                if !klass.type_vars.empty? && !ann["name"]
                  ann.raise "Failed to auto register service for '#{klass}'. Generic services must explicitly provide a name."
                end
              %}

              {%
                SERVICE_HASH[service_id] = {
                  class:             klass.resolve,
                  factory:           factory,
                  shared:            klass.class?,
                  calls:             [] of Nil,
                  configurator:      nil,
                  tags:              definition_tags,
                  public:            ann[:public] == true,
                  decorated_service: nil,
                  bindings:          {} of Nil => Nil,
                  generics:          ann.args,
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
