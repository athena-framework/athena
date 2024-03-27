# :nodoc:
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

                if restriction && restriction <= String && !value.is_a? StringLiteral
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects a String but got '#{value}'."
                end

                if (s = SERVICE_HASH[value.stringify]) && !(s["class"] <= restriction)
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects '#{restriction}' but" \
                          " the resolved service '#{value.id}' is of type '#{s["class"].id}'."
                end
              elsif !param["resolved_restriction"].nilable?
                error = "Failed to resolve value for parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]})."
              end

              param["arg"].raise error if error
            end
          end
        %}

        # Validate the user provided configuration against the defined schema
        {%
          _nil = nil

          # This is mostly copied from `RegisterExtensions` code,
          # ideally would be nice to be able to not share state like this but :shrug: this works for now.
          #
          # That would be easiest with some macros defs to share the macro logic of building out this map.
          EXTENSION_SCHEMA_PROPERTIES_MAP.each do |ext_name, schema_properties|
            user_provided_extension_config = CONFIG[ext_name]

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
                                        if member_map = prop["members"]
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
                                      elsif cfv.is_a?(TypeNode) || cfv.is_a?(HashLiteral)
                                        cfv
                                      elsif cfv.is_a?(NamedTupleLiteral)
                                        if member_map = prop["members"]
                                          prop_type = member_map
                                        end

                                        # The prop type is from an (array|object)_of, so we need to fill in defaults
                                        if prop_type.is_a?(NamedTupleLiteral)
                                          provided_keys = cfv.keys

                                          prop_type.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                            decl = prop_type[k]

                                            # Skip setting required values so that it results in a missing error vs type mismatch error
                                            cfv[k] = decl.value unless decl.value.is_a?(Nop)
                                          end

                                          # Use the member_map as is if not processing an `array_of` object so that missing required properties are properly enforced.
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

                                            cfv.raise "Expected configuration value '#{ext_name.id}.#{path.id}' to be a '#{prop_type}', but encountered unexpected key '#{k}' with value '#{v}'."
                                          elsif k == "__nil"
                                            # no-op
                                          else
                                            type = nt_key_type.is_a?(TypeDeclaration) ? nt_key_type.type : nt_key_type

                                            values_to_resolve << {type.resolve, v, stack + [k]}
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

                      if resolved_type && resolved_type.stringify != "Nop"
                        values_to_resolve[idx][2] = resolved_type

                        # Handles outer most typing issues.
                        if resolved_type.is_a?(TypeNode) && !(resolved_type <= prop_type)
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
