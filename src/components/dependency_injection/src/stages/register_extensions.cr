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
                ext_schema_config = ext_config[config_key] = {enabled: true}
              end

              properties.each do |prop|
                pp! prop

                if (config_value = ext_schema_config[prop.var]) != nil
                  config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                  resolved_type = if config_value.is_a?(BoolLiteral)
                                    Bool
                                  elsif config_value.is_a?(StringLiteral)
                                    String
                                  elsif config_value.is_a?(ArrayLiteral)
                                    if (array_type = (config_value.of || config_value.type)).is_a? Nop
                                      config_value.raise "Array configuration value '#{ext_name.id}.#{config_key}.#{prop.var}' must specify its type."
                                    end

                                    parse_type("Array(#{array_type})").resolve
                                  elsif config_value.is_a?(NumberLiteral)
                                    kind = config_value.kind

                                    if kind.starts_with? 'i'
                                      parse_type("Int#{kind[1..].id}").resolve
                                    elsif kind.starts_with? 'u'
                                      parse_type("UInt#{kind[1..].id}").resolve
                                    elsif kind.starts_with? 'f'
                                      parse_type("Float#{kind[1..].id}").resolve
                                    else
                                      config_value.raise "BUG: Unexpected number literal value"
                                    end
                                  else
                                    parse_type("#{config_value.class_name.id}").resolve
                                  end

                  unless prop.type.resolve <= resolved_type
                    config_value.raise "Expected configuration value '#{ext_name.id}.#{config_key}.#{prop.var}' to be a '#{prop.type}', but got '#{resolved_type}'."
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

                ext_schema_config[prop.var] = if resolved_value.is_a?(Nop)
                                                nil
                                              else
                                                resolved_value
                                              end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
