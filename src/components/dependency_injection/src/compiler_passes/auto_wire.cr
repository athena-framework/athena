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
              # 1. The first service if there is only 1 option
              # 2. If the constructor parameter name explicitly matches service ID
              # 3. Constructor parameter type is aliased to another service

              resolved_service = if resolved_services.size == 1
                                   resolved_services[0]
                                 elsif rs = resolved_services.find(&.==(name.id))
                                   rs
                                 elsif a = ALIASES.keys.find { |k| k == param_resolved_restriction }
                                   ALIASES[a]["id"]
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
