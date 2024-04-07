# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ProcessAliases
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            interface_modules = definition["class"].ancestors.select { |a| a.name.ends_with? "Interface" }
            default_alias = 1 == interface_modules.size ? interface_modules[0] : nil

            if ann = definition["class"].annotation ADI::AsAlias
              alias_id = if name = ann[0]
                           name.is_a?(Path) ? name.resolve : name
                         else
                           default_alias
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
