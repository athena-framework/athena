# :nodoc:
module Athena::DependencyInjection::ServiceContainer::MergeExtensionConfig
  private EXTENSION_SCHEMA_PROPERTIES_MAP = {} of Nil => Nil

  macro included
    macro finished
      {% verbatim do %}

        # In order to keep extensions local to the DI component, they must be registered via a dedicated macro call.
        # This includes the name of the extension and its schema.
        # If the extension has any compiler passes (including the extension itself), those must be registered via a dedicated macro call as well.
        # This setup keeps things pretty de-coupled; allowing use of extensions/compiler passes if used outside of the Framework.

        {%
          _nil = nil

          # Array of tuples representing all of the extension types that are to be processed.
          # 0 : String - name of the extension
          # 1 : Array(String) - represents the path from root of the extension to this child extension type
          # 2 : TypeNode - extension type
          extensions_to_process = [] of Nil

          extension_schema_map = {} of Nil => Nil

          # For each extension type, register its base type
          ADI::ServiceContainer::EXTENSIONS.each do |name, ext|
            extensions_to_process << {name.id, [] of Nil, ext.resolve}
          end

          # For each base type, determine all child extension types
          extensions_to_process.each do |(ext_name, ext_path, ext)|
            ext.constants.reject(&.==("OPTIONS")).each do |sub_ext|
              t = parse_type("::#{ext}::#{sub_ext}").resolve

              # We only want to process sub extension modules, not just any primitive constant defined within these types
              if t.is_a? TypeNode
                extensions_to_process << {ext_name, ext_path + [sub_ext.stringify.underscore.downcase.id], t}
              end
            end
          end

          # For each extension to register, build out a schema hash consisting of the schema types related to each extension
          extensions_to_process.each do |(ext_name, ext_path, ext)|
            if extension_schema_map[ext_name] == nil
              ext_options = extension_schema_map[ext_name] = {__nil: nil} # Ensure this is a NamedTupleLiteral
              EXTENSION_SCHEMA_PROPERTIES_MAP[ext_name] = [] of Nil
            end

            ext.constant("OPTIONS").each do |o|
              obj = ext_options

              if ext_path.empty?
                obj[o["name"]] = o
                EXTENSION_SCHEMA_PROPERTIES_MAP[ext_name] << {o, ext_path}
              else
                ext_path.each_with_index do |k, idx|
                  obj[k] = {} of Nil => Nil if obj[k] == nil
                  obj = obj[k]

                  if idx == ext_path.size - 1
                    obj[o["name"]] = o
                    EXTENSION_SCHEMA_PROPERTIES_MAP[ext_name] << {o, ext_path}
                  end
                end
              end
            end
          end

          # Validate there is no configuration for un-registered extensions
          extra_keys = CONFIG.keys.reject { |k| k == "parameters".id || k == "__nil".id } - extension_schema_map.keys

          unless extra_keys.empty?
            CONFIG[extra_keys.first].raise "Extension '#{extra_keys.first.id}' is configured, but no extension with that name has been registered."
          end

          EXTENSION_SCHEMA_PROPERTIES_MAP.each do |ext_name, schema_properties|
            # Ensure the root CONFIG obj has a key for each extension
            unless extension_config = CONFIG[ext_name]
              extension_config = CONFIG[ext_name] = {__nil: nil} # Ensure this is a NamedTupleLiteral
            end

            # Iterate over each schema property to process them
            schema_properties.each do |(prop, ext_path)|
              extension_schema_for_current_property = extension_schema_map[ext_name]
              extension_config_for_current_property = extension_config

              ext_path.each do |p|
                extension_schema_for_current_property = extension_schema_for_current_property[p] if extension_schema_for_current_property

                # Ensure this is a NamedTupleLiteral, expand user provided value to include defaults from schema if not provided
                extension_config_for_current_property[p] = {__nil: nil} if extension_config_for_current_property[p] == nil
                extension_config_for_current_property = extension_config_for_current_property[p]
              end

              # If the user provided configuration, check for unexpected keys
              extra_keys = extension_config_for_current_property.keys.reject { |k| k == "__nil".id } - extension_schema_for_current_property.keys

              unless extra_keys.empty?
                extra_key_value = extension_config_for_current_property[extra_keys.first]

                extra_key_value.raise "Encountered unexpected property '#{([ext_name] + ext_path).join('.').id}.#{extra_keys.first.id}' with value '#{extra_key_value}'."
              end

              # Then handle any light transformations needed to get the configuration value into the expected format/type
              if (config_value = extension_config_for_current_property[prop["name"]]) != nil
                config_value = config_value.is_a?(Path) ? config_value.resolve : config_value

                resolved_value = if config_value.is_a?(SymbolLiteral) && (type = prop["type"]) <= ::Enum
                                   config_value.raise "Unknown '#{type}' enum member '#{config_value}' for property '#{([ext_name] + ext_path).join('.').id}.#{prop["name"]}'." unless type.constants.any?(&.downcase.id.==(config_value.id))

                                   # Resolve symbol literals to enum members
                                   config_value = "#{type}.new(#{config_value})".id
                                 elsif config_value.is_a?(NumberLiteral) && (type = prop["type"]) <= ::Enum
                                   # Resolve enum value to enum members
                                   config_value = "#{type}.new(#{config_value})".id
                                 elsif config_value.is_a?(NamedTupleLiteral)
                                   # Fill in `nil` values to missing nilable NT keys
                                   if member_map = prop["members"]
                                     member_map.each do |k, decl|
                                       if config_value[k] == nil && decl && decl.type.resolve.nilable?
                                         config_value[k] = nil
                                       end
                                     end
                                   else
                                     p = prop["type"]

                                     p.keys.each do |k|
                                       t = p[k]

                                       if config_value[k] == nil && t.nilable?
                                         config_value[k] = nil
                                       end
                                     end
                                   end

                                   config_value
                                 else
                                   config_value
                                 end
              else
                # Otherwise fall back on the default value of the property
                resolved_value = if prop["default"].is_a?(Nop)
                                   nil
                                 elsif prop["default"].is_a?(Path)
                                   prop["default"].resolve
                                 else
                                   default_value = prop["default"]

                                   # Resolve symbol literals to enum members
                                   if default_value.is_a?(SymbolLiteral) && (type = prop["type"]) <= ::Enum
                                     config_value.raise "Unknown '#{type}' enum member '#{default_value}' for default value of property '#{([ext_name] + ext_path).join('.').id}.#{prop["name"]}'." unless type.constants.any?(&.downcase.id.==(default_value.id))

                                     # Resolve symbol literals to enum members
                                     default_value = "#{type}.new(#{default_value})".id
                                   end

                                   default_value
                                 end
              end

              extension_config_for_current_property[prop["name"]] = resolved_value
            end
          end
        %}
      {% end %}
    end
  end
end
