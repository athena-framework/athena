# :nodoc:
module Athena::DependencyInjection::ServiceContainer::AutoWire
  macro included
    macro finished
      {% verbatim do %}
        {%
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

              if resolved_services.size == 1
                resolved_service = resolved_services[0]
              elsif rs = resolved_services.find(&.==(name.id))
                resolved_service = rs
              elsif s = SERVICE_HASH[(param_resolved_restriction && param_resolved_restriction < ADI::Proxy ? param_resolved_restriction.type_vars.first.resolve : param_resolved_restriction)]
                resolved_service = s["class"].name.gsub(/::/, "_").underscore
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
