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

            extensions_to_process << {ext_ann[0], [] of Nil, ext}
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
              ext_options = extension_schema_map[ext_name.id] = {} of Nil => Nil
              extension_schema_properties_map[ext_name.id] = [] of Nil
            end

            ext.constant("OPTIONS").each do |o|
              obj = ext_options

              ext_path.each_with_index do |k, idx|
                obj[k] = {} of Nil => Nil if obj[k] == nil
                obj = obj[k]

                if idx == ext_path.size - 1
                  obj[o.var.id] = o
                  extension_schema_properties_map[ext_name.id] << {o, ext_path}
                end
              end
            end
          end

          p! extension_schema_map, extension_schema_properties_map
          puts ""

          extension_schema_properties_map.each do |ext_name, schema_properties|
            user_provided_extension_config = CONFIG[ext_name]

            if user_provided_extension_config == nil
              user_provided_extension_config = CONFIG[ext_name] = {} of Nil => Nil
            end

            p! user_provided_extension_config
            puts ""

            schema_properties.each do |(prop, ext_path)|
              pp! ext_path

              extension_schema_for_current_property = extension_schema_map[ext_name]
              user_provided_extension_config_for_current_property = user_provided_extension_config

              ext_path.each do |p|
                extension_schema_for_current_property = extension_schema_for_current_property[p]
                user_provided_extension_config_for_current_property = user_provided_extension_config_for_current_property[p]
              end

              pp! extension_schema_for_current_property, user_provided_extension_config_for_current_property

              extra_keys = user_provided_extension_config_for_current_property.keys - extension_schema_for_current_property.keys

              unless extra_keys.empty?
                extra_key_value = user_provided_extension_config_for_current_property[extra_keys.first]

                extra_key_value.raise "Encountered unexpected key '#{extra_keys.first.id}' with value '#{extra_key_value}' within '#{ext_name.id}.#{ext_path.join('.').id}'."
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
