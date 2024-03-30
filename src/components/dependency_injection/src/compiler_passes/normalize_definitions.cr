# :nodoc:
#
# Runs after extensions to normalize the manually wired up services.
# Ensures required keys are present and with proper defaults if not specified.
module Athena::DependencyInjection::ServiceContainer::NormalizeDefinitions
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            definition_keys = definition.keys.map &.stringify

            unless definition_keys.includes? "class"
              definition.raise "Service '#{service_id.id}' is missing required 'class' property."
            end

            unless definition_keys.includes? "public"
              definition["public"] = false
            end

            unless definition_keys.includes? "shared"
              definition["shared"] = definition["class"].class?
            end

            unless definition_keys.includes? "calls"
              definition["calls"] = [] of Nil
            end

            unless definition_keys.includes? "tags"
              definition["tags"] = {} of Nil => Nil
            end

            unless definition_keys.includes? "bindings"
              definition["bindings"] = {} of Nil => Nil
            end

            unless definition_keys.includes? "parameters"
              definition["parameters"] = {} of Nil => Nil
            end

            unless definition_keys.includes? "generics"
              definition["generics"] = [] of Nil
            end

            unless definition_keys.includes? "aliases"
              definition["aliases"] = [] of Nil
            end
          end
        %}
      {% end %}
    end
  end
end
