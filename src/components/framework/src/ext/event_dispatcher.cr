@[ADI::Register(name: "event_dispatcher", public: true)]
@[ADI::AsAlias(AED::EventDispatcherInterface)]
@[ADI::AsAlias(ACTR::EventDispatcher::Interface)]
class AED::EventDispatcher; end

# :nodoc:
module Athena::Framework::EventDispatcher::CompilerPasses::RegisterEventListenersPass
  macro included
    macro finished
      {% verbatim do %}
        {%
          event_dispatcher_service = SERVICE_HASH["event_dispatcher"]

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
        %}
      {% end %}
    end
  end
end
