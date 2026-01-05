# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ProcessAliases
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            interface_modules = definition["class"].ancestors.select &.name.ends_with? "Interface"
            default_alias = 1 == interface_modules.size ? interface_modules[0] : nil

            definition["class"].annotations(ADI::AsAlias).each do |ann|
              alias_id = if alias_type = ann[0]
                           alias_type.is_a?(Path) ? alias_type.resolve : alias_type
                         else
                           default_alias
                         end

              unless alias_id
                ann.raise <<-TXT
                Alias cannot be automatically determined for '#{service_id.id}' (#{definition["class"]}). \
                If the type includes multiple interfaces, provide the interface to alias as the first positional argument to `@[ADI::AsAlias]`.
                TXT
              end

              param_name = ann["name"]

              # Initialize the array for this alias type if needed
              ALIASES[alias_id] = [] of Nil if ALIASES[alias_id].nil?

              # Check for duplicate type+name combination
              if ALIASES[alias_id].any? { |a| a["name"] == param_name }
                if param_name
                  ann.raise "Duplicate alias for type '#{alias_id}' with name '#{param_name.id}'. " \
                            "An alias with this type and name combination is already registered."
                else
                  ann.raise "Duplicate alias for type '#{alias_id}'. " \
                            "A type-only alias for this type is already registered."
                end
              end

              ALIASES[alias_id] << {
                id:     service_id,
                public: ann["public"] == true,
                name:   param_name,
              }
            end
          end
        %}
      {% end %}
    end
  end
end
