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
              # pp! o, ext_path
              obj = ext_options

              ext_path.each_with_index do |k, idx|
                obj[k] = {} of Nil => Nil if obj[k] == nil
                obj = obj[k]

                if idx == ext_path.size - 1
                  obj[o.var.id] = o
                  pp! o
                  extension_schema_properties_map[ext_name] << {o, ext_path}
                else
                end
              end
            end

            # Insert placeholder property to ensure empty namespaces get checked for extraneous keys
            extension_schema_properties_map[ext_name] << {nil, ext_path}
          end

          puts ""
          p! extension_schema_map, extension_schema_properties_map
          puts ""

          # Validate there is no configuration for un-registerd extensions
          extra_keys = CONFIG.keys.reject(&.==("parameters".id)) - extension_schema_map.keys

          unless extra_keys.empty?
            CONFIG[extra_keys.first].raise "Extension '#{extra_keys.first.id}' is configured, but no extension with that name has been registered."
          end

          extension_schema_properties_map.each do |ext_name, schema_properties|
            user_provided_extension_config = CONFIG[ext_name]

            if user_provided_extension_config == nil
              user_provided_extension_config = CONFIG[ext_name] = {} of Nil => Nil
            end

            # p! user_provided_extension_config
            puts ""

            schema_properties.each do |(prop, ext_path)|
              # pp! ext_path, prop
              puts ""

              extension_schema_for_current_property = extension_schema_map[ext_name]
              user_provided_extension_config_for_current_property = user_provided_extension_config

              ext_path.each do |p|
                extension_schema_for_current_property = extension_schema_for_current_property[p]
                user_provided_extension_config_for_current_property = user_provided_extension_config_for_current_property[p]
              end

              # pp! extension_schema_for_current_property, user_provided_extension_config_for_current_property

              extra_keys = user_provided_extension_config_for_current_property.keys - extension_schema_for_current_property.keys

              unless extra_keys.empty?
                extra_key_value = user_provided_extension_config_for_current_property[extra_keys.first]

                extra_key_value.raise "Encountered unexpected key '#{extra_keys.first.id}' with value '#{extra_key_value}' within '#{ext_name.id}.#{ext_path.join('.').id}'."
              end

              puts ""
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
