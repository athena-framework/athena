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
              alias_id = if name = ann[0]
                           name.is_a?(Path) ? name.resolve : name
                         else
                           default_alias
                         end

              unless alias_id
                ann.raise <<-TXT
                Alias cannot be automatically determined for '#{service_id.id}' (#{definition["class"]}). \
                If the type includes multiple interfaces, provide the interface to alias as the first positional argument to `@[ADI::AsAlias]`.
                TXT
              end

              ALIASES[alias_id] = {
                id:     service_id,
                public: ann["public"] == true,
              }
            end
          end
        %}
      {% end %}
    end
  end
end
