# :nodoc:
#
# Processes `@[ADI::Autoconfigure]` annotations
module Athena::DependencyInjection::ServiceContainer::ProcessAutoconfigureAnnotations
  macro included
    macro finished
      {% verbatim do %}
        {%
          __nil = nil

          # Build out a list of types we need to process.
          # I.e. that have an applicable annotation.
          #
          # Array(TypeNode)
          types_to_process = [] of Nil

          # Used interface modules (this only captures modules that would be included in at least 1 used type)
          Object.all_subclasses.each do |sc|
            sc.ancestors.each do |a|
              # TODO: Use `#private?` once available.
              if a.module? && (m = parse_type(a.name(generic_args: false).stringify).resolve?) && m.annotation ADI::Autoconfigure
                types_to_process << m
              end
            end
          end

          # Parent services
          SERVICE_HASH.each do |_, definition|
            types_to_process << definition["class"] if definition["class"].annotation ADI::Autoconfigure
          end

          SERVICE_HASH.each do |service_id, definition|
            types_to_process.each do |t|
              if definition["class"] <= t
                ann = t.annotation ADI::Autoconfigure

                if (v = ann["bind"]) != nil
                  v.each do |k, v|
                    definition["bindings"][k] = v
                  end
                end

                if (v = ann["public"]) != nil
                  definition["public"] = v
                end

                if (v = ann["calls"]) != nil
                  calls = [] of Nil

                  v.each do |call|
                    method = call[0]
                    args = call[1] || nil
                    klass = definition["class"]

                    if method.empty?
                      method.raise "Method name cannot be empty."
                    end

                    unless klass.resolve.has_method?(method)
                      method.raise "Failed to auto register service for '#{service_id.id}' (#{klass}). Call references non-existent method '#{method.id}'."
                    end

                    calls << {method, args || [] of Nil}
                  end

                  definition["calls"] = calls
                end

                if (v = ann["tags"]) != nil
                  unless v.is_a? ArrayLiteral
                    v.raise "Tags for auto configuration of '#{t.id}' must be an 'ArrayLiteral', got '#{v.class_name.id}'."
                  end

                  # TODO: Centralize tag handling logic between AutoConfigure and RegisterServices
                  v.each do |tag|
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

                    definition["tags"][name] = [] of Nil if definition["tags"][name] == nil
                    definition["tags"][name] << attributes
                    definition["tags"][name] = definition["tags"][name].uniq

                    TAG_HASH[name] = [] of Nil if TAG_HASH[name] == nil
                    TAG_HASH[name] << {service_id, attributes}
                    TAG_HASH[name] = TAG_HASH[name].uniq
                  end
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
