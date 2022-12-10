module Athena::Framework::CompilerPasses::RegisterEventListenersPass
  include Athena::DependencyInjection::PreArgumentsCompilerPass

  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH["event_dispatcher"][:factory] = {"self".id, "get_event_dispatcher"}

          TAG_HASH["athena.event_dispatcher.listener"].each do |service_id|
            SERVICE_HASH[service_id][:visibility] = Visibility::INTERNAL
          end
        %}

        private def get_event_dispatcher
          dispatcher = AED::EventDispatcher.new

          {% for service_id in TAG_HASH["athena.event_dispatcher.listener"] %}
            {% metadata = SERVICE_HASH[service_id] %}

            # Changes made here should also be reflected within `AED::EventListenerInterface` overload within `AED::EventDispatcher`.
            # E.g. changes to the error handling logic.
            {% for m in metadata[:service].methods.select &.annotation(AEDA::AsEventListener) %}
              {% ann = m.annotation AEDA::AsEventListener %}
              {% event = m.args[0].restriction || m.args[0].raise "No resetriction" %}

              {% if 1 == m.args.size %}
                dispatcher.add_listener(
                  {{event}},
                  AED::EventDispatcher::OneType.new do |event|
                    self.{{service_id.id}}.{{m.name.id}} event.as({{event}})
                 end,
                  priority: {{ann[:priority] || 0}},
                )
              {% else %}
                dispatcher.add_listener(
                  {{event}},
                  AED::EventDispatcher::TwoType.new do |event, dispatcher|
                    self.{{service_id.id}}.{{m.name.id}} event.as({{event}}), dispatcher
                  end,
                  priority: {{ann[:priority] || 0}},
                )
              {% end %}
            {% end %}
          {% end %}

          dispatcher
        end
      {% end %}
    end
  end
end
