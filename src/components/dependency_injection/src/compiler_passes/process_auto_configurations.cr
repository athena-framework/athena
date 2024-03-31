# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ProcessAutoConfigurations
  macro included
    macro finished
      {% verbatim do %}
        {%
          AUTO_CONFIGURATIONS.keys.each do |key|
            auto_configuration = AUTO_CONFIGURATIONS[key]

            if (v = auto_configuration["tags"]) != nil
              if !v.is_a?(ArrayLiteral) && !v.is_a?(StringLiteral) && !v.is_a?(Path)
                auto_configuration.raise "Tags for auto configuration of '#{key.id}' must be an 'ArrayLiteral', got '#{v.class_name.id}'."
              end

              v = v.is_a?(ArrayLiteral) ? v : [v]

              v.each do |t|
                name = if t.is_a?(StringLiteral)
                         t
                       elsif t.is_a?(Path)
                         t.resolve.id.stringify
                       elsif t.is_a?(NamedTupleLiteral) || t.is_a?(HashLiteral)
                         if t["name"].is_a? Path
                           t["name"] = t["name"].resolve
                         end

                         t["name"]
                       else
                         t.raise "Tag '#{t}' must be a 'StringLiteral' or 'NamedTupleLiteral', got '#{t.class_name.id}'."
                       end

                TAG_HASH[name] = [] of Nil if TAG_HASH[name] == nil
              end
            end
          end

          SERVICE_HASH.each do |service_id, definition|
            tags = [] of Nil

            AUTO_CONFIGURATIONS.keys.select(&.>=(definition["class"])).each do |key|
              auto_configuration = AUTO_CONFIGURATIONS[key]

              if (v = auto_configuration["bind"]) != nil
                v.each do |k, v|
                  definition["bindings"][k] = v
                end
              end

              if (v = auto_configuration["public"]) != nil
                definition["public"] = v
              end

              if (v = auto_configuration["tags"]) != nil
                tags += v
              end

              # TODO: Configurator?
            end

            definition_tags = definition["tags"]

            # TODO: Centralize tag handling logic between AutoConfigure and RegisterServices
            tags.each do |tag|
              name, attributes = if tag.is_a?(StringLiteral)
                                   {tag, {} of Nil => Nil}
                                 elsif tag.is_a?(Path)
                                   {tag.resolve.id.stringify, {} of Nil => Nil}
                                 elsif tag.is_a?(NamedTupleLiteral) || tag.is_a?(HashLiteral)
                                   tag.raise "Failed to register service '#{service_id.id}'. All tags must have a name." unless tag[:name]

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
