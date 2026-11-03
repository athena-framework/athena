# :nodoc:
#
# Registers services with an `AEDA::AsEventListener` annotated method as listeners of the `event_dispatcher` service, if the [Event Dispatcher](/EventDispatcher/) component is present.
#
# A service tagged `event_dispatcher.listener` is registered with the event dispatcher service whose ID is the `dispatcher` attribute of each of these tags instead.
# A tag without a `dispatcher` attribute registers it with the default `event_dispatcher` service.
module Athena::DependencyInjection::ServiceContainer::RegisterEventListeners
  macro included
    macro finished
      {% verbatim do %}
        {%
          if @top_level.has_constant?("AED")
            SERVICE_HASH.each do |service_id, definition|
              # Include types with the annotation applied to class methods for proper error handling.
              if (klass = definition["class"]).is_a?(TypeNode) &&
                 (
                   klass.class.methods.any?(&.annotation AEDA::AsEventListener) ||
                   klass.methods.any?(&.annotation AEDA::AsEventListener)
                 )
                event_dispatcher_ids = [] of Nil

                if listener_tags = definition["tags"]["event_dispatcher.listener"]
                  listener_tags.each do |attributes|
                    event_dispatcher_ids << (attributes["dispatcher"] || "event_dispatcher")
                  end
                else
                  event_dispatcher_ids << "event_dispatcher"
                end

                event_dispatcher_ids.each do |event_dispatcher_id|
                  unless event_dispatcher_service = SERVICE_HASH[event_dispatcher_id]
                    raise "Service '#{service_id.id}' is a listener of the '#{event_dispatcher_id.id}' event dispatcher, which does not exist."
                  end

                  event_dispatcher_service["calls"] << {"listener", {service_id.id}}
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
