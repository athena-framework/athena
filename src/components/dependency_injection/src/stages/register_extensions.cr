# :nodoc:
module Athena::DependencyInjection::ServiceContainer::RegisterExtensions
  macro included
    macro finished
      {% verbatim do %}
        {%
          _nil = nil

          # Array of tuples representing all of the extension types that are to be processed.
          # 0 : String - name of the extension
          # 1 : Array(String) - represents the path from root of the extension to this child extension type
          # 2 : TypeNode - extension type
          extensions_to_process = [] of Nil

          extension_schema_map = {} of Nil => Nil
          extension_schema_properties_map = {} of Nil => Nil

          # For each extension type, register its base type
          Object.all_subclasses.select(&.annotation(ADI::RegisterExtension)).each do |ext|
            ext_ann = ext.annotation ADI::RegisterExtension

            extensions_to_process << {ext_ann[0].id, [] of Nil, ext}
          end

          # For each base type, determine all child extension types
          extensions_to_process.each do |(ext_name, ext_path, ext)|
            ext.constants.reject(&.==("OPTIONS")).each do |sub_ext|
              extensions_to_process << {ext_name, ext_path + [sub_ext.stringify.downcase.id], parse_type("::#{ext}::#{sub_ext}").resolve}
            end
          end

          p! extensions_to_process
          puts ""
          puts ""

          # For each extension to register, build out a schema hash
          extensions_to_process.each do |(ext_name, ext_path, ext)|
            if extension_schema_map[ext_name] == nil
              ext_options = extension_schema_map[ext_name] = {} of Nil => Nil
              extension_schema_properties_map[ext_name] = [] of Nil
            end

            ext.constant("OPTIONS").each do |o|
              obj = ext_options

              ext_path.each_with_index do |k, idx|
                obj[k] = {} of Nil => Nil if obj[k] == nil
                obj = obj[k]

                if idx == ext_path.size - 1
                  obj[o.var.id] = o
                  extension_schema_properties_map[ext_name] << {o, ext_path}
                end
              end
            end

            # Insert placeholder property to ensure empty namespaces get checked for extraneous keys
            extension_schema_properties_map[ext_name] << {nil, ext_path}
          end

          puts ""
          p! extension_schema_map
          puts ""
          pp! extension_schema_properties_map
          puts ""

          # Validate there is no configuration for un-registered extensions
          extra_keys = CONFIG.keys.reject(&.==("parameters".id)) - extension_schema_map.keys

          unless extra_keys.empty?
            CONFIG[extra_keys.first].raise "Extension '#{extra_keys.first.id}' is configured, but no extension with that name has been registered."
          end

          extension_schema_properties_map.each do |ext_name, schema_properties|
            user_provided_extension_config = CONFIG[ext_name]

            if user_provided_extension_config == nil
              user_provided_extension_config = CONFIG[ext_name] = {} of Nil => Nil
            end

            schema_properties.each do |(prop, ext_path)|
              extension_schema_for_current_property = extension_schema_map[ext_name]
              user_provided_extension_config_for_current_property = user_provided_extension_config

              ext_path.each do |p|
                extension_schema_for_current_property = extension_schema_for_current_property[p]
                user_provided_extension_config_for_current_property = user_provided_extension_config_for_current_property[p]
              end

              extra_keys = user_provided_extension_config_for_current_property.keys - extension_schema_for_current_property.keys

              unless extra_keys.empty?
                extra_key_value = user_provided_extension_config_for_current_property[extra_keys.first]

                extra_key_value.raise "Encountered unexpected key '#{extra_keys.first.id}' with value '#{extra_key_value}' within '#{ext_name.id}.#{ext_path.join('.').id}'."
              end

              if prop
                if (config_value = user_provided_extension_config_for_current_property[prop.var.id]) != nil
                  config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                  # Tuple of:
                  # 0 - type of the property in the schema
                  # 1 - the value
                  values_to_resolve = [{prop.type.resolve, config_value, ext_path + [prop.var.id]}]

                  values_to_resolve.each_with_index do |(prop_type, cfv, stack), idx|
                    resolved_type = if cfv.is_a?(BoolLiteral)
                                      Bool
                                    elsif cfv.is_a?(StringLiteral)
                                      String
                                    elsif cfv.is_a?(ArrayLiteral)
                                      if (array_type = (cfv.of || cfv.type)).is_a? Nop
                                        cfv.raise "Array configuration value '#{ext_name.id}.#{ext_name.id}.#{config_key}.#{pv.var}' must specify its type."
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

                  resolved_value = config_value
                elsif prop.value.is_a?(Nop) && !prop.type.resolve.nilable?
                  path = ext_name

                  path += ".#{config_key}" unless "root" == config_key
                  path += ".#{prop}"

                  prop.raise "Required configuration value '#{path.id}' must be provided."
                else
                  resolved_value = if prop.value.is_a?(Nop)
                                     nil
                                   elsif prop.value.is_a?(Path)
                                     prop.value.resolve
                                   else
                                     prop.value
                                   end
                end

                user_provided_extension_config_for_current_property[prop.var] = resolved_value
              end
            end
          end

          puts ""
          puts ""
          puts ""
          pp CONFIG
        %}
      {% end %}
    end
  end
end
