# :nodoc:
#
# Compiler pass that merges user-provided configuration with extension schema defaults.
#
# This pass handles two main scenarios for each schema property:
#   1. User provided a value: Transform it as needed (e.g., resolve enums, fill in default values for missing object members)
#   2. User didn't provide a value: Use the schema's default value
#
# Key concepts:
#   - CONFIG: User-provided configuration (from ADI.configure)
#   - OPTIONS: Schema property definitions (from extension.cr macros)
#   - member_map: For array_of/object_of/map_of, describes the structure of each element.
#     Members can be TypeDeclaration (simple) or NamedTupleLiteral (object_schema ref).
#   - map_of properties use `prop["type"] <= Hash` as their identifying marker
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
                                   config_value = "#{prop["global"] ? "::".id : "".id}#{type}.new(#{config_value})".id
                                 elsif config_value.is_a?(NumberLiteral) && (type = prop["type"]) <= ::Enum
                                   # Resolve enum value to enum members
                                   config_value = "#{prop["global"] ? "::".id : "".id}#{type}.new(#{config_value})".id
                                 elsif config_value.is_a?(ArrayLiteral)
                                   # If there is an array literal and the prop has `members`,
                                   # assume it is an `array_of` schema property array and fill in unprovided fields.
                                   if member_map = prop["members"]
                                     config_value.each do |cfv|
                                       provided_keys = cfv.keys

                                       # We only want to add in missing default values, so reject any properties that were provided, even if they may be incorrect.
                                       member_map.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                         decl = member_map[k]

                                         # Handle both TypeDeclaration and NamedTupleLiteral (for nested object_schema)
                                         decl_value = decl.is_a?(TypeDeclaration) ? decl.value : decl["value"]
                                         # Skip setting required values so that it results in a missing error vs type mismatch error.
                                         cfv[k] = decl_value unless decl_value.is_a?(Nop)
                                       end

                                       # Recursively fill in defaults for nested object_schema members
                                       member_map.keys.reject { |k| k.stringify == "__nil" }.each do |k|
                                         decl = member_map[k]
                                         if decl.is_a?(NamedTupleLiteral) && (nested_members = decl["members"]) && (nested_cfv = cfv[k])
                                           nested_provided_keys = nested_cfv.keys
                                           nested_members.keys.reject { |nk| nk.stringify == "__nil" || nested_provided_keys.includes? nk }.each do |nk|
                                             nested_decl = nested_members[nk]
                                             nested_decl_value = nested_decl.is_a?(TypeDeclaration) ? nested_decl.value : nested_decl["value"]
                                             nested_cfv[nk] = nested_decl_value unless nested_decl_value.is_a?(Nop)
                                           end
                                         end
                                       end
                                     end
                                   end

                                   config_value
                                 elsif config_value.is_a?(NamedTupleLiteral)
                                   # NamedTupleLiteral handles three cases:
                                   #   1. map_of values: {key1: {members...}, key2: {members...}}
                                   #   2. object_of values: {member1: val, member2: val}
                                   #   3. Inline NamedTuple type properties
                                   #
                                   # Check if this is a map_of property (type is Hash and has members).
                                   if prop["type"] <= Hash && (member_map = prop["members"])
                                     config_value.each do |hash_key, cfv|
                                       if hash_key != "__nil"
                                         provided_keys = cfv.keys

                                         member_map.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                           decl = member_map[k]

                                           # Handle both TypeDeclaration and NamedTupleLiteral (for nested object_schema)
                                           decl_value = decl.is_a?(TypeDeclaration) ? decl.value : decl["value"]
                                           # Skip setting required values so that it results in a missing error vs type mismatch error.
                                           cfv[k] = decl_value unless decl_value.is_a?(Nop)
                                         end

                                         # Recursively fill in defaults for nested object_schema members
                                         member_map.keys.reject { |k| k.stringify == "__nil" }.each do |k|
                                           decl = member_map[k]
                                           if decl.is_a?(NamedTupleLiteral) && (nested_members = decl["members"]) && (nested_cfv = cfv[k])
                                             nested_provided_keys = nested_cfv.keys
                                             nested_members.keys.reject { |nk| nk.stringify == "__nil" || nested_provided_keys.includes? nk }.each do |nk|
                                               nested_decl = nested_members[nk]
                                               nested_decl_value = nested_decl.is_a?(TypeDeclaration) ? nested_decl.value : nested_decl["value"]
                                               nested_cfv[nk] = nested_decl_value unless nested_decl_value.is_a?(Nop)
                                             end
                                           end
                                         end
                                       end
                                     end

                                     config_value
                                     # Fill in `nil` values to missing nilable NT keys
                                   elsif member_map = prop["members"]
                                     provided_keys = config_value.keys

                                     # We only want to add in missing default values, so reject any properties that were provided, even if they may be incorrect.
                                     member_map.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                       decl = member_map[k]

                                       # Handle both TypeDeclaration and NamedTupleLiteral (for nested object_schema)
                                       if decl.is_a?(TypeDeclaration)
                                         # If the value has a default, use it.
                                         # Otherwise skip setting required values so that it results in a missing error vs type mismatch error.
                                         if !decl.value.is_a?(Nop)
                                           config_value[k] = decl.value
                                         elsif decl.type.resolve.nilable?
                                           config_value[k] = nil
                                         end
                                       elsif decl.is_a?(NamedTupleLiteral)
                                         # Nested object_schema reference
                                         decl_value = decl["value"]
                                         config_value[k] = decl_value unless decl_value.is_a?(Nop)
                                       end
                                     end

                                     # Recursively fill in defaults for nested object_schema members
                                     member_map.keys.reject { |k| k.stringify == "__nil" }.each do |k|
                                       decl = member_map[k]
                                       if decl.is_a?(NamedTupleLiteral) && (nested_members = decl["members"]) && (nested_cfv = config_value[k])
                                         nested_provided_keys = nested_cfv.keys
                                         nested_members.keys.reject { |nk| nk.stringify == "__nil" || nested_provided_keys.includes? nk }.each do |nk|
                                           nested_decl = nested_members[nk]
                                           nested_decl_value = nested_decl.is_a?(TypeDeclaration) ? nested_decl.value : nested_decl["value"]
                                           nested_cfv[nk] = nested_decl_value unless nested_decl_value.is_a?(Nop)
                                         end
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
                                     default_value = "#{prop["global"] ? "::".id : "".id}#{type}.new(#{default_value})".id
                                   elsif default_value.is_a?(ArrayLiteral)
                                     # If there is an array literal and the prop has `members`,
                                     # assume it is an `array_of` schema property array and fill in unprovided fields.
                                     if member_map = prop["members"]
                                       default_value.each do |cfv|
                                         provided_keys = cfv.keys

                                         # We only want to add in missing default values, so reject any properties that were provided, even if they may be incorrect.
                                         member_map.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                           decl = member_map[k]

                                           # Skip setting required values so that it results in a missing error vs type mismatch error.
                                           cfv[k] = decl.value unless decl.value.is_a?(Nop)
                                         end
                                       end
                                     end

                                     default_value
                                   elsif default_value.is_a?(NamedTupleLiteral)
                                     # Fill in `nil` values to missing nilable NT keys
                                     # Skip for map_of properties - the empty map default shouldn't have member defaults filled in
                                     if !(prop["type"] <= Hash) && (member_map = prop["members"])
                                       provided_keys = default_value.keys

                                       # We only want to add in missing default values, so reject any properties that were provided, even if they may be incorrect.
                                       member_map.keys.reject { |k| k.stringify == "__nil" || provided_keys.includes? k }.each do |k|
                                         decl = member_map[k]

                                         # Handle both TypeDeclaration and NamedTupleLiteral (for nested object_schema)
                                         if decl.is_a?(TypeDeclaration)
                                           # If the value has a default, use it.
                                           # Otherwise skip setting required values so that it results in a missing error vs type mismatch error.
                                           if !decl.value.is_a?(Nop)
                                             default_value[k] = decl.value
                                           elsif decl.type.resolve.nilable?
                                             default_value[k] = nil
                                           end
                                         elsif decl.is_a?(NamedTupleLiteral)
                                           # Nested object_schema reference
                                           decl_value = decl["value"]
                                           default_value[k] = decl_value unless decl_value.is_a?(Nop)
                                         end
                                       end
                                     end
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
