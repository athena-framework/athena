# :nodoc:
module Athena::DependencyInjection::ServiceContainer::AutoWire
  macro included
    macro finished
      {% verbatim do %}
        {%
          printed = false

          SERVICE_HASH.each do |_, definition|
            definition["parameters"].each do |name, param|
              param_resolved_restriction = param["resolved_restriction"]
              resolved_services = [] of Nil

              # Gather a list of services that are compatible with the parameter's type restriction.
              SERVICE_HASH.each do |id, s_metadata|
                if (type = param_resolved_restriction) &&
                   (
                     s_metadata["class"] <= type ||
                     (type < ADI::Proxy && s_metadata["class"] <= type.type_vars.first.resolve)
                   )
                  resolved_services << id
                end
              end

              # If only one service was resolved use it, but only if the parameter is typed as a non-module.
              # This prevents parameters typed as an interface from being resolved if there is only a single implementation.
              #
              # These services should be wired up as aliases to prevent errors if/when another implementation is added.
              resolved_service = if resolved_services.size == 1 && !param_resolved_restriction.module?
                                   resolved_services[0]

                                   # If there are more than one, try and match the parameter's name to a service ID.
                                 elsif rs = resolved_services.find(&.==(name.id))
                                   rs

                                   # Otherwise see if any aliases explicitly match the parameter's type restriction.
                                 elsif a = ALIASES.keys.find { |k| k == param_resolved_restriction }
                                   aliases_for_type = ALIASES[a]

                                   # Try named alias first (more specific match by parameter name)
                                   named_alias = aliases_for_type.find { |entry| entry["name"] && entry["name"].id == name.id }

                                   if named_alias
                                     named_alias["id"]
                                   else
                                     # Fall back to type-only alias
                                     type_only_alias = aliases_for_type.find(&.["name"].nil?)
                                     type_only_alias ? type_only_alias["id"] : nil
                                   end
                                 end

              if resolved_service
                if param["resolved_restriction"] < ADI::Proxy
                  param["value"] = "ADI::Proxy.new(#{resolved_service}, ->#{resolved_service.id})".id
                  # Track proxy references to ensure getters are generated
                  definition["referenced_services"] << resolved_service
                else
                  param["value"] = resolved_service.id
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
