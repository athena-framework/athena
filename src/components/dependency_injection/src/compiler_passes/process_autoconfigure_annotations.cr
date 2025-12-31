# :nodoc:
#
# Processes `@[ADI::Autoconfigure]` annotations
module Athena::DependencyInjection::ServiceContainer::ProcessAutoconfigureAnnotations
  macro included
    macro finished
      {% verbatim do %}
        {%
          __nil = nil

          # Build out a list of interfaces, and types that can be used to autoconfigure other services
          #
          # Array(TypeNode)
          types_to_process = [] of Nil

          # Use `Object.all_subclasses` since some autoconfigured types may not be services themselves.
          Object.all_subclasses.each do |sc|
            # Used interface modules (this only captures modules that would be included in at least 1 used type)
            sc.ancestors.each do |a|
              # TODO: Use `#private?` once available.
              if a.module? && (m = parse_type(a.name(generic_args: false).stringify).resolve?) && (m.annotation(ADI::Autoconfigure) || m.annotation(ADI::AutoconfigureTag))
                types_to_process << m
              end
            end

            # Non module types that may be the parent type of a service.
            types_to_process << sc if sc.annotation(ADI::Autoconfigure) || sc.annotation(ADI::AutoconfigureTag)
          end

          # Don't process types more than once.
          types_to_process = types_to_process.uniq

          SERVICE_HASH.each do |service_id, definition|
            klass = definition["class"]

            types_to_process.each do |t|
              if definition["class"] <= t
                tags = [] of Nil

                if at = t.annotation(ADI::AutoconfigureTag)
                  tag_name = if n = at[0]
                               if n.is_a?(Path)
                                 n.resolve
                               else
                                 n
                               end
                             else
                               t.stringify
                             end

                  tag = {name: tag_name}

                  at.named_args.each do |k, v|
                    tag[k.id.stringify] = v
                  end

                  tags << tag
                end

                ann = t.annotation ADI::Autoconfigure

                if ann && (v = ann["constructor"])
                  definition["factory"] = {definition["class"], v}
                end

                if ann && (v = ann["bind"]) != nil
                  v.each do |k, v|
                    definition["bindings"][k] = v
                  end
                end

                if ann && (v = ann["public"]) != nil
                  definition["public"] = v
                end

                if ann && (v = ann["calls"]) != nil
                  calls = [] of Nil

                  v.each do |call|
                    method = call[0]
                    args = call[1] || nil

                    if method.empty?
                      method.raise "Auto configuration '#{t.id}': 'calls' method name cannot be empty."
                    end

                    unless klass.resolve.has_method?(method)
                      method.raise "Auto configuration '#{t.id}': 'calls' method does not exist on service '#{service_id.id}' (#{klass})."
                    end

                    calls << {method, args || [] of Nil}
                  end

                  definition["calls"] = calls
                end

                if ann && (v = ann["tags"]) != nil
                  unless v.is_a? ArrayLiteral
                    v.raise "'tags' field of auto configuration '#{t.id}' must be an 'ArrayLiteral', got '#{v.class_name.id}'."
                  end

                  v.each do |t|
                    tags << t
                  end
                end

                # Append raw tags - will be normalized by ProcessTags pass
                tags.each do |tag|
                  definition["tags"] << tag
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
