# :nodoc:
#
# Sets the value of parameters with the `ADI::TaggedIterator` annotation automatically.
# See also DefineTaggedIterators for how `Iterator` types are handled.
module Athena::DependencyInjection::ServiceContainer::ResolveTaggedIterators
  macro included
    macro finished
      {% verbatim do %}
        {%
          iterator_service_map = {} of Nil => Nil

          SERVICE_HASH.each do |service_id, definition|
            definition["parameters"].each do |_, param|
              if ann = param["declaration"].annotation ADI::TaggedIterator
                param_type = param["resolved_restriction"]
                base_collection_type = param_type.name(generic_args: false).stringify

                unless {"Enumerable", "Iterator", "Indexable"}.includes? base_collection_type
                  param["declaration"].raise <<-TEXT
                  Failed to register service '#{service_id.id}' (#{definition["class"]}). \
                  Collection type must be one of 'Indexable', 'Iterator', or 'Enumerable'. Got '#{param_type.name(generic_args: false).id}'.
                  TEXT
                end

                enumerable_type = param_type.type_vars.first

                # If no tag name was explicitly provided, assume its the FQN of the enumerable type
                tag_name = if name = ann[0]
                             if name.is_a?(Path)
                               name.resolve
                             else
                               name
                             end
                           elsif enumerable_type.union?
                             ann.raise "Unable to support unions"
                           else
                             enumerable_type.stringify
                           end

                iterator_service_map[iterator_id = "#{service_id.id}_iterator"] = {
                  type:     enumerable_type,
                  services: (TAG_HASH[tag_name] || [] of Nil)
                    .sort_by { |(_tmp, attributes)| -(attributes["priority"] || 0) }
                    .map(&.first.id),
                }

                param["value"] = "@#{iterator_id.id}"
              end
            end
          end
        %}

        # Define iterator types
        {% for name, metadata in iterator_service_map %}
          ADI.service_iterator({{name}}, {{metadata["services"]}})
        {% end %}

        # Register iterator services
        {%
          iterator_service_map.each do |name, metadata|
            SERVICE_HASH[name] = {
              class:      name.camelcase,
              bindings:   {} of Nil => Nil,
              generics:   [metadata["type"], metadata["services"].size] of Nil,
              calls:      [] of Nil,
              parameters: {
                container: {value: "self".id},
              },
            }
          end
        %}
      {% end %}
    end
  end
end
