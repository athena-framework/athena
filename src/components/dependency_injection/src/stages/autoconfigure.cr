# :nodoc:
module Athena::DependencyInjection::ServiceContainer::Autoconfigure
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            tags = definition["class_ann"]["tags"] || [] of Nil

            unless tags.is_a? ArrayLiteral
              definition["class_ann"].raise "Tags for '#{service_id.id}' must be an 'ArrayLiteral', got '#{tags.class_name.id}'."
            end

            auto_configuration_tags = nil

            AUTO_CONFIGURATIONS.keys.select(&.>=(definition["class"])).each do |key|
              auto_configuration = AUTO_CONFIGURATIONS[key]

              if (v = auto_configuration["bind"]) != nil
                v.each do |k, v|
                  definition["bindings"][k.id.stringify] = v
                end
              end

              if (v = auto_configuration["public"]) != nil
                definition["public"] = v
              end

              if (v = auto_configuration["tags"]) != nil
                unless v.is_a? ArrayLiteral
                  definition["class_ann"].raise "Tags for '#{service_id.id}' must be an 'ArrayLiteral', got '#{v.class_name.id}'."
                end

                tags += v
              end

              # TODO: Configurator?
            end

            # Process both autoconfiguration tags and normal tags here to keep the logic somewhat centralized.

            definition_tags = definition["tags"]

            tags.each do |tag|
              name, attributes = if tag.is_a?(StringLiteral)
                                   {tag, {} of Nil => Nil}
                                 elsif tag.is_a?(Path)
                                   {tag.resolve.id.stringify, {} of Nil => Nil}
                                 elsif tag.is_a?(NamedTupleLiteral) || tag.is_a?(HashLiteral)
                                   tag.raise "Failed to register service '#{service_id.id}'.  All tags must have a name." unless tag[:name]

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
          end
        %}
      {% end %}
    end
  end
end
