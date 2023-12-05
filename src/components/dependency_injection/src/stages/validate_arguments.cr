# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ValidateArguments
  macro included
    macro finished
      {% verbatim do %}
        # Resolve the arguments for each service
        {%
          SERVICE_HASH.each do |service_id, definition|
            definition["parameters"].each do |_, param|
              error = nil

              # Type of the param matches param restriction
              if param["value"] != nil
                value = param["value"]
                restriction = param["resolved_restriction"]

                if restriction && restriction <= String && !value.is_a? StringLiteral
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects a String but got '#{value}'."
                end

                if (s = SERVICE_HASH[value.stringify]) && !(s["class"] <= restriction)
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects '#{restriction}' but" \
                          " the resolved service '#{service_id.id}' is of type '#{s["class"].id}'."
                end
              elsif !param["resolved_restriction"].nilable?
                error = "Failed to resolve value for parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]})."
              end

              param["arg"].raise error if error
            end
          end
        %}

        # Validate
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
                user_provided_extension_config_for_current_property = user_provided_extension_config_for_current_property[p]
              end

              if prop
                if (config_value = user_provided_extension_config_for_current_property[prop.var.id]) != nil
                  config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                  # Tuple of:
                  # 0 - type of the property in the schema
                  # 1 - the value
                  # 2 - an array representing the path to this property in the schema
                  values_to_resolve = [{prop.type.resolve, config_value, ext_path + [prop.var.id]}]

                  values_to_resolve.each_with_index do |(prop_type, cfv, stack), idx|
                    resolved_type = if cfv.is_a?(BoolLiteral)
                                      Bool
                                    elsif cfv.is_a?(StringLiteral)
                                      String
                                    elsif cfv.is_a?(ArrayLiteral)
                                      if (array_type = (cfv.of || cfv.type)).is_a? Nop
                                        cfv.raise "Array configuration value '#{ext_name.id}.#{stack.join('.').id}' must specify its type: #{cfv.id} of #{prop.type.type_vars.join(" | ").id}"
                                      end

                                      cfv.each_with_index do |v, v_idx|
                                        values_to_resolve << {array_type.resolve, v, stack + [v_idx]}
                                      end

                                      parse_type("Array(#{array_type})").resolve
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
                                    elsif cfv.is_a?(HashLiteral)
                                      cfv.raise "TODO: Support HashLiterals"
                                    elsif cfv.is_a?(NamedTupleLiteral)
                                      cfv.each do |k, v|
                                        nt_key_type = prop_type[k]

                                        if nt_key_type == nil
                                          path = "#{stack[0]}"

                                          stack[1..].each do |p|
                                            path += if p.is_a?(NumberLiteral)
                                                      "[#{p}]"
                                                    else
                                                      ".#{p}"
                                                    end
                                          end

                                          cfv.raise "Expected configuration value '#{ext_name.id}.#{path.id}' to be a '#{prop_type}', but encountered unexpected key '#{k}' with value '#{v}'."
                                        end

                                        values_to_resolve << {nt_key_type.resolve, v, stack + [k]}
                                      end

                                      missing_keys = prop_type.keys - cfv.keys

                                      unless missing_keys.empty?
                                        missing_keys.each do |mk|
                                          unless prop_type[mk].nilable?
                                            path = "#{stack[0]}"

                                            stack[1..].each do |p|
                                              path += if p.is_a?(NumberLiteral)
                                                        "[#{p}]"
                                                      else
                                                        ".#{p}"
                                                      end
                                            end

                                            cfv.raise "Configuration value '#{ext_name.id}.#{path.id}' is missing required value for '#{mk}' of type '#{prop_type[mk]}'."
                                          end
                                        end
                                      end

                                      # TODO: Figure out if there's a way to get a TypeNode reference to the named tuple instance itself.
                                      nil
                                    end

                    unless resolved_type.nil?
                      values_to_resolve[idx][2] = resolved_type

                      # Handles outer most typing issues.
                      unless resolved_type <= prop_type
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
                elsif prop.value.is_a?(Nop) && !prop.type.resolve.nilable?
                  path = "#{ext_path[0]}"

                  ext_path[1..].each do |p|
                    path += if p.is_a?(NumberLiteral)
                              "[#{p}]"
                            else
                              ".#{p}"
                            end
                  end

                  prop.raise "Required configuration property '#{ext_name.id}.#{path.id}.#{prop.var.id}' must be provided."
                end
              end
            end
          end
        %}

        {%
          _nil = nil
          puts ""
          puts ""
          puts ""
          pp CONFIG
        %}
      {% end %}
    end
  end
end
