# :nodoc:
#
# Compiler pass that validates user-provided configuration against extension schemas.
#
# Uses a queue-based approach (values_to_resolve) to handle nested validation:
#   - Start with the top-level config value
#   - For array_of/map_of/object_of, queue each element/member for validation
#   - Process until queue is empty
#
# Key concepts:
#   - prop_type: Can be TypeNode (for type checking) or NamedTupleLiteral (member map for nested objects)
#   - schema_member_map_prop_cache: Prevents re-processing the same property's members (since queued items share the same `prop`, we only want to expand members once)
#   - map_of properties identified by `prop["type"] <= Hash`
#   - Member entries can be TypeDeclaration (simple) or NamedTupleLiteral (object_schema ref)
module Athena::DependencyInjection::ServiceContainer::ValidateArguments
  macro included
    macro finished
      {% verbatim do %}
        # Validate the arguments for each service
        {%
          SERVICE_HASH.each do |service_id, definition|
            definition["parameters"].each do |_, param|
              error = nil

              # Type of the resolved argument matches the method param restriction
              if param["value"] != nil
                value = param["value"]
                restriction = param["resolved_restriction"]

                if restriction && restriction <= String && (!value.is_a?(StringLiteral) && !value.is_a?(Call))
                  error = "Parameter '#{param["declaration"]}' of service '#{service_id.id}' (#{definition["class"]}) expects a String but got '#{value}'."
                end

                if (s = SERVICE_HASH[value.stringify]) && (klass = s["class"]).is_a?(TypeNode) && !(klass <= restriction)
                  error = "Parameter '#{param["declaration"]}' of service '#{service_id.id}' (#{definition["class"]}) expects '#{restriction}' but" \
                          " the resolved service '#{value.id}' is of type '#{s["class"].id}'."
                end
              elsif !param["resolved_restriction"].nilable?
                error = "Failed to resolve value for parameter '#{param["declaration"]}' of service '#{service_id.id}' (#{definition["class"]})."
              end

              if error
                param["declaration"].raise error
              end
            end
          end
        %}

        # Validate the user provided configuration against the defined schema
        {%
          _nil = nil

          # This is mostly copied from `MergeExtensionConfig` code,
          # ideally would be nice to be able to not share state like this but :shrug: this works for now.
          #
          # That would be easiest with some macros defs to share the macro logic of building out this map.
          EXTENSION_SCHEMA_PROPERTIES_MAP.each do |ext_name, schema_properties|
            user_provided_extension_config = CONFIG[ext_name]

            schema_member_map_prop_cache = {} of Nil => Nil

            schema_properties.each do |(prop, ext_path)|
              user_provided_extension_config_for_current_property = user_provided_extension_config

              ext_path.each do |p|
                user_provided_extension_config_for_current_property = user_provided_extension_config_for_current_property[p] if user_provided_extension_config_for_current_property
              end

              # If this schema property maps to an actual property, and the user provided some configuration value for that property, move onto validating the provided value's validity.
              # Otherwise, if that property was not provided, and is required, raise an exception.

              if prop
                # If the configuration property was not provided and is required, throw an error
                if !user_provided_extension_config_for_current_property
                  if prop["default"].is_a?(Nop) && !prop["type"].resolve.nilable?
                    path = [ext_name]

                    unless ext_path.empty?
                      ext_path.each do |p|
                        path << if p.is_a?(NumberLiteral)
                          "[#{p}]"
                        else
                          "#{p}"
                        end
                      end
                    end

                    prop["root"].raise "Required configuration property '#{path.join('.').id}.#{prop["name"]} : #{prop["type"]}' must be provided."
                  end
                else
                  if (config_value = user_provided_extension_config_for_current_property[prop["name"]]) != nil
                    config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                    # Tuple of:
                    # 0 - type of the property in the schema
                    # 1 - the value
                    # 2 - an array representing the path to this property in the schema
                    values_to_resolve = [{prop["type"], config_value, ext_path + [prop["name"]]}]

                    values_to_resolve.each_with_index do |(prop_type, cfv, stack), idx|
                      resolved_type = if cfv.nil?
                                        Nil
                                      elsif cfv.is_a?(BoolLiteral)
                                        Bool
                                      elsif cfv.is_a?(StringLiteral)
                                        String
                                      elsif cfv.is_a?(SymbolLiteral)
                                        Symbol
                                      elsif cfv.is_a?(RegexLiteral)
                                        Regex
                                      elsif cfv.is_a?(ArrayLiteral)
                                        # Because each value to resolve has the same `prop`, we only want to process the prop's members once.
                                        # Otherwise next iterations cfv will be correct, but the prop_type will be a named tuple literal.
                                        if schema_member_map_prop_cache[prop["name"]] == nil && (member_map = prop["members"])
                                          schema_member_map_prop_cache[prop["name"]] = true
                                          cfv.each_with_index do |v, v_idx|
                                            values_to_resolve << {member_map, v, stack + [v_idx]}
                                          end

                                          Array
                                        else
                                          # If the type is a union, extract the first non-nilable type.
                                          # Then fallback on the type of the property if no type could be extracted/was provided
                                          non_nilable_prop_type = prop_type.union? ? prop_type.union_types.reject(&.nilable?).first : prop_type
                                          array_type = (cfv.of || cfv.type) || non_nilable_prop_type.type_vars.first

                                          cfv.each_with_index do |v, v_idx|
                                            values_to_resolve << {array_type.resolve, v, stack + [v_idx]}
                                          end

                                          parse_type("Array(#{array_type})").resolve
                                        end
                                      elsif cfv.is_a?(NumberLiteral)
                                        kind = cfv.kind

                                        if kind.starts_with? 'i'
                                          parse_type("Int#{kind[1..].id}").resolve
                                        elsif kind.starts_with? 'u'
                                          parse_type("UInt#{kind[1..].id}").resolve
                                        elsif kind.starts_with? 'f'
                                          parse_type("Float#{kind[1..].id}").resolve
                                        else
                                          cfv.raise "BUG: Unexpected number literal value"
                                        end
                                      elsif cfv.is_a?(TypeNode)
                                        cfv
                                      elsif cfv.is_a?(NamedTupleLiteral)
                                        # NamedTupleLiteral handles: map_of values, object_of values, and inline NamedTuples.
                                        #
                                        # Check if this is a map_of property (type is Hash and has members)
                                        if prop["type"] <= Hash && schema_member_map_prop_cache[prop["name"]] == nil && (member_map = prop["members"])
                                          schema_member_map_prop_cache[prop["name"]] = true
                                          cfv.each do |hash_key, v|
                                            if hash_key != "__nil"
                                              values_to_resolve << {member_map, v, stack + [hash_key]}
                                            end
                                          end

                                          Hash
                                        else
                                          # Because each value to resolve has the same `prop`, we only want to process the prop's members once.
                                          # Otherwise next iterations cfv will be correct, but the prop_type will be a named tuple literal.
                                          if schema_member_map_prop_cache[prop["name"]] == nil && (member_map = prop["members"])
                                            schema_member_map_prop_cache[prop["name"]] = true
                                            prop_type = member_map
                                          end

                                          cfv.each do |k, v|
                                            nt_key_type = prop_type[k]

                                            if nt_key_type == nil && k != "__nil"
                                              path = "#{stack[0]}"

                                              stack[1..].each do |p|
                                                path += if p.is_a?(NumberLiteral)
                                                          "[#{p}]"
                                                        else
                                                          ".#{p}"
                                                        end
                                              end

                                              # Filter out internal __nil key for cleaner error message
                                              display_type = "{#{prop_type.keys.reject { |dk| dk.stringify == "__nil" }.map { |dk| "#{dk}: #{prop_type[dk]}" }.join(", ").id}}"
                                              cfv.raise "Expected configuration value '#{ext_name.id}.#{path.id}' to be a '#{display_type.id}', but encountered unexpected key '#{k}' with value '#{v}'."
                                            elsif k == "__nil"
                                              # no-op
                                            else
                                              type = if nt_key_type.is_a?(TypeDeclaration)
                                                       nt_key_type.type.resolve
                                                     elsif nt_key_type.is_a?(NamedTupleLiteral)
                                                       # Nested object_schema reference - pass the members map
                                                       nt_key_type["members"]
                                                     else
                                                       nt_key_type.resolve
                                                     end

                                              values_to_resolve << {type, v, stack + [k]}
                                            end
                                          end

                                          missing_keys = prop_type.keys.reject { |k| k.stringify == "__nil" } - cfv.keys

                                          unless missing_keys.empty?
                                            missing_keys.each do |mk|
                                              mt = prop_type[mk]

                                              can_be_missing = if mt.is_a?(TypeNode)
                                                                 mt.nilable?
                                                               elsif mt.is_a?(TypeDeclaration)
                                                                 mt.type.resolve.nilable? || !mt.value.is_a?(Nop)
                                                               elsif mt.is_a?(NamedTupleLiteral)
                                                                 # For nested object_schema references
                                                                 !mt["value"].is_a?(Nop)
                                                               else
                                                                 false
                                                               end

                                              unless can_be_missing
                                                path = "#{stack[0]}"

                                                stack[1..].each do |p|
                                                  path += if p.is_a?(NumberLiteral)
                                                            "[#{p}]"
                                                          else
                                                            ".#{p}"
                                                          end
                                                end

                                                type = prop_type[mk]
                                                type = type.is_a?(TypeDeclaration) ? type.type : type

                                                cfv.raise "Configuration value '#{ext_name.id}.#{path.id}' is missing required value for '#{mk}' of type '#{type}'."
                                              end
                                            end
                                          end

                                          nil
                                        end
                                      end

                      if resolved_type
                        # Handles outer most typing issues.
                        # Skip type check when prop_type is a NamedTupleLiteral (member map for nested validation)
                        if resolved_type.is_a?(TypeNode) && prop_type.is_a?(TypeNode) && !(resolved_type <= prop_type)
                          path = "#{stack[0]}"

                          stack[1..].each do |p|
                            path += if p.is_a?(NumberLiteral)
                                      "[#{p}]"
                                    else
                                      ".#{p}"
                                    end
                          end

                          cfv.raise "Expected configuration value '#{ext_name.id}.#{path.id}' to be a '#{prop_type}', but got '#{resolved_type}'."
                        end
                      end
                    end
                  elsif prop["default"].is_a?(Nop) && !prop["type"].resolve.nilable?
                    path = [ext_name]

                    unless ext_path.empty?
                      ext_path.each do |p|
                        path << if p.is_a?(NumberLiteral)
                          "[#{p}]"
                        else
                          "#{p}"
                        end
                      end
                    end

                    prop["root"].raise "Required configuration property '#{path.join('.').id}.#{prop["name"]} : #{prop["type"]}' must be provided."
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
