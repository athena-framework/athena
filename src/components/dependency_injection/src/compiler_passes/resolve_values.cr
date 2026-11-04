# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ResolveValues
  macro included
    macro finished
      {% verbatim do %}

          # Resolves the constructor arguments for each service in the container.
          # The values should be provided in priority order:
          #
          # 1. Explicit value on annotation => _id
          # 2. Bindings (typed and untyped) => `ADI.bind` > `ADI::Autoconfigure`
          # 3. Autowire => By direct type, or parameter name
          # 4. Service Alias => Service registered with `AsAlias` of a specific interface
          # 5. Default value => some_value : Int32 = 123
          # 6. Nilable Type => nil

        {%
          SERVICE_HASH.each do |service_id, definition|
            # Use a dedicated array var such that we can use the pseudo recursion trick
            parameters = definition["parameters"].map { |_tmp, param| {param["value"], param, nil} }

            parameters.each do |(unresolved_value, param, reference)|
              # Parameter reference
              if unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('%') && unresolved_value.ends_with?('%')
                resolved_value = CONFIG["parameters"][unresolved_value[1..-2]]

                # Service reference
              elsif unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('@')
                service_name = unresolved_value[1..-1]

                # Resolve the alias ID to its underlying ID
                # For explicit @service_name references, take the first alias entry
                if aliases = ALIASES[service_name]
                  service_name = aliases.first["id"]
                end

                if SERVICE_HASH[service_name].nil?
                  unresolved_value.raise "Service '#{service_id.id}' (#{definition["class"]}) references undefined service '#{service_name.id}'."
                end

                resolved_value = service_name.id

                # Tagged services
              elsif unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('!')
                tag_name = unresolved_value[1..]

                # Sort based on tag priority.  Services without a priority will be last in order of definition
                tagged_services = (TAG_HASH[tag_name] || [] of Nil).sort_by { |(_tmp, attributes)| -(attributes["priority"] || 0) }

                if param["resolved_restriction"].type_vars.first.resolve < ADI::Proxy
                  # Track proxy references to ensure getters are generated
                  definition["referenced_services"] = [] of Nil unless definition["referenced_services"]
                  tagged_services.each do |(id, attributes)|
                    definition["referenced_services"] << id
                  end
                  tagged_services = tagged_services.map do |(id, attributes)|
                    {"ADI::Proxy.new(#{id}, ->#{id.id})".id}
                  end
                end

                resolved_value = tagged_services.map &.first.id

                # Service locator, providing the services of the hash by their key
              elsif unresolved_value.is_a?(HashLiteral) &&
                    (!reference || "scalar" == reference["type"]) &&
                    (restriction = param["resolved_restriction"]) && restriction < ADI::ServiceLocator
                service_type = restriction.type_vars.first.resolve
                factories = [] of Nil

                unresolved_value.each do |key, value|
                  unless key.is_a?(StringLiteral)
                    key.raise "Service '#{service_id.id}' (#{definition["class"]}) must key the services of its '#{param["name"].id}' service locator by a 'StringLiteral', got '#{key.class_name.id}'."
                  end

                  unless value.is_a?(StringLiteral) && value.starts_with?('@')
                    value.raise "Service '#{service_id.id}' (#{definition["class"]}) must provide the services of its '#{param["name"].id}' service locator as service references, e.g. '@service_id', got '#{value}'."
                  end

                  service_name = value[1..-1]

                  # Resolve the alias ID to its underlying ID
                  if aliases = ALIASES[service_name]
                    service_name = aliases.first["id"]
                  end

                  unless provided_service = SERVICE_HASH[service_name]
                    value.raise "Service '#{service_id.id}' (#{definition["class"]}) references undefined service '#{service_name.id}'."
                  end

                  if (provided_class = provided_service["class"]).is_a?(TypeNode) && !(provided_class <= service_type)
                    value.raise "Service '#{service_id.id}' (#{definition["class"]}) cannot provide the '#{service_name.id}' service (#{provided_class}) via its '#{param["name"].id}' service locator, as it is not a '#{service_type}'."
                  end

                  # Track the provided services to ensure their getters are generated
                  definition["referenced_services"] << service_name

                  factories << "#{key} => ->{ #{service_name.id}.as(#{service_type}) }"
                end

                resolved_value = "ADI::ServiceLocator(#{service_type}).new({#{factories.join(", ").id}} of String => Proc(#{service_type}))".id

                # Array, could contain nested references
              elsif unresolved_value.is_a?(ArrayLiteral) || unresolved_value.is_a?(TupleLiteral)
                # Pseudo recurse over each array element
                resolved_value = unresolved_value

                unresolved_value.each_with_index do |v, idx|
                  parameters << {v, param, {type: "array", key: idx, value: resolved_value}}
                end

                # Hash, could contain nested references
              elsif unresolved_value.is_a?(HashLiteral)
                # Pseudo recurse over each key/value pair
                resolved_value = unresolved_value

                unresolved_value.each do |k, v|
                  parameters << {v, param, {type: "hash", key: k, value: resolved_value}}
                end
                # Bound value, only apply if value was not already resolved
                # Value is re-processed to resolve the underlying value, use the reference value to know not to do it again
              elsif (bv = definition["bindings"][param["name"].id]) != nil && !reference
                resolved_value = nil

                parameters << {bv, param, {type: "scalar"}}

                # Scalar value
              else
                resolved_value = unresolved_value
              end

              if reference && ("array" == reference["type"] || "hash" == reference["type"])
                reference["value"][reference[:key]] = resolved_value
              else
                param["value"] = resolved_value
              end

              # Clear temp vars to avoid confusion
              resolved_value = nil
              unresolved_value = nil
            end
          end
        %}
      {% end %}
    end
  end
end
