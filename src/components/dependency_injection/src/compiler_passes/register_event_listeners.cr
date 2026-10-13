# :nodoc:
#
# Registers services with an `AEDA::AsEventListener` annotated method as listeners of the `event_dispatcher` service, if the [Event Dispatcher](/EventDispatcher/) component is present.
module Athena::DependencyInjection::ServiceContainer::RegisterEventListeners
  macro included
    macro finished
      {% verbatim do %}
        {%
          if @top_level.has_constant?("AED") && (event_dispatcher_service = SERVICE_HASH["event_dispatcher"])
            SERVICE_HASH.each do |service_id, definition|
              # Include types with the annotation applied to class methods for proper error handling.
              if (klass = definition["class"]).is_a?(TypeNode) &&
                 (
                   klass.class.methods.any?(&.annotation AEDA::AsEventListener) ||
                   klass.methods.any?(&.annotation AEDA::AsEventListener)
                 )
                event_dispatcher_service["calls"] << {"listener", {service_id.id}}
              end
            end
          end
        %}
      {% end %}
    end
  end
end
