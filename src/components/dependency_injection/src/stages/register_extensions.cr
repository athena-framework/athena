# :nodoc:
#
# TODO: Currently extensions are registered via `ADI.register_extension` in which accepts the name of the extension as a string and a named tuple representing its schema.
# The schema uses TupleLiterals of TypeDeclaration to represent the name, type, and default value of each option.
# This works fine, but requires the extension creator to manually document the possible configuration options manually in another location.
# A more robust future approach might be to do something more like `ADI.register_extension ATH::Extension`,
# where the type's getters/constructor may be used to represent the configuration options' name, type, and default value, and what they are used for.
# This way things would be automatically documented as new things are added/changed, and this compiler stage could consume the data from the type to do what it is currently doing.
module Athena::DependencyInjection::ServiceContainer::RegisterExtensions
  macro included
    macro finished
      {% verbatim do %}
        {%
          EXTENSIONS.each do |ext_name, schema|
            ext_config = CONFIG[ext_name]

            if ext_config == nil
              ext_config = CONFIG[ext_name] = {} of Nil => Nil
            end

            schema.each do |config_key, properties|
              ext_schema_config = ext_config[config_key]

              if ext_schema_config == nil
                ext_schema_config = ext_config[config_key] = {} of Nil => Nil
              end

              extra_keys = ext_schema_config.keys - properties.map(&.var)

              unless extra_keys.empty?
                extra_key_value = ext_schema_config[extra_keys.first]

                ext_schema_config.raise "Encountered unexpected key '#{extra_keys.first.id}' with value '#{extra_key_value}' within '#{ext_name.id}.#{config_key}'."
              end

              properties.each do |prop|
                if (config_value = ext_schema_config[prop.var]) != nil
                  config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                  # Tuple of:
                  # 0 - type of the property in the schema
                  # 1 - the value
                  # 2 - stack keeping track of current path to the value
                  values_to_resolve = [{prop.type.resolve, config_value, [ext_name.id, config_key.id, prop.var.id]}]

                  values_to_resolve.each_with_index do |(prop_type, cfv, stack), idx|
                    resolved_type = if cfv.is_a?(BoolLiteral)
                                      Bool
                                    elsif cfv.is_a?(StringLiteral)
                                      String
                                    elsif cfv.is_a?(ArrayLiteral)
                                      if (array_type = (cfv.of || cfv.type)).is_a? Nop
                                        cfv.raise "Array configuration value '#{ext_name.id}.#{config_key}.#{prop.var}' must specify its type."
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

                                          cfv.raise "Expected configuration value '#{path.id}' to be a '#{prop_type}', but encountered unexpected key '#{k}' with value '#{v}'."
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

                                            cfv.raise "Configuration value '#{path.id}' is missing required value for '#{mk}' of type '#{prop_type[mk]}'."
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

                        config_value.raise "Expected configuration value '#{path.id}' to be a '#{prop_type}', but got '#{resolved_type}'."
                      end
                    end
                  end

                  resolved_value = config_value
                elsif prop.value.is_a?(Nop) && !prop.type.resolve.nilable?
                  prop.raise "Required configuration value '#{ext_name.id}.#{config_key}.#{prop}' must be provided."
                else
                  resolved_value = if prop.value.is_a?(Nop)
                                     nil
                                   elsif prop.value.is_a?(Path)
                                     prop.value.resolve
                                   else
                                     prop.value
                                   end
                end

                ext_schema_config[prop.var] = resolved_value
              end
            end
          end
        %}
      {% end %}
    end
  end
end
