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

              # Otherwise resolve possible services based on type
              SERVICE_HASH.each do |id, s_metadata|
                if (type = param_resolved_restriction) &&
                   (
                     s_metadata["class"] <= type ||
                     (type < ADI::Proxy && s_metadata["class"] <= type.type_vars.first.resolve)
                   )
                  resolved_services << id
                end
              end

              resolved_service = nil

              # Try and determine the service to used in priority order:
              #
              # 1. Use only resolved service
              # 2. If the constructor arg explicitly matches service ID
              # 3. Explicit match on the type of the constructor arg
              # 4. The first valid alias based on type

              if resolved_services.size == 1
                resolved_service = resolved_services[0]
              elsif rs = resolved_services.find(&.==(name.id))
                resolved_service = rs
              elsif s = SERVICE_HASH[(param_resolved_restriction && param_resolved_restriction < ADI::Proxy ? param_resolved_restriction.type_vars.first.resolve : param_resolved_restriction)]
                resolved_service = s["alias_service_id"]
              else
                resolved_service = resolved_services.first
              end

              if resolved_service
                param["value"] = if param["resolved_restriction"] < ADI::Proxy
                                   "ADI::Proxy.new(#{resolved_service}, ->#{resolved_service.id})".id
                                 else
                                   resolved_service.id
                                 end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
