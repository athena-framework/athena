@[ADI::Register(name: "event_dispatcher", alias: AED::EventDispatcherInterface, public: true)]
class AED::EventDispatcher
end

module Athena::Framework::EventDispatcher::Listeners
  TAG = "athena.event_dispatcher.listener"
end

@[ADI::Autoconfigure(tags: [ATH::EventDispatcher::Listeners::TAG])]
module AED::EventListenerInterface; end

# :nodoc:
module Athena::Framework::EventDispatcher::CompilerPasses::RegisterEventListenersPass
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH["event_dispatcher"]["factory"] = {"self".id, "get_event_dispatcher"}
        %}

        private def get_event_dispatcher
          dispatcher = AED::EventDispatcher.new

          {%
            listeners = [] of Nil

            (TAG_HASH[ATH::EventDispatcher::Listeners::TAG] || [] of Nil).each do |(service_id, _attributes)|
              metadata = SERVICE_HASH[service_id]

              class_listeners = metadata["class"].class.methods.select &.annotation(AEDA::AsEventListener)

              # Raise compile time error if a listener is defined as a class method.
              unless class_listeners.empty?
                class_listeners.first.raise "Event listener methods can only be defined as instance methods. Did you mean '#{metadata["class"].name}##{class_listeners.first.name}'?"
              end

              metadata["class"].methods.select(&.annotation(AEDA::AsEventListener)).each do |m|
                # Validate the parameters of each method.
                if (m.args.size < 1) || (m.args.size > 2)
                  m.raise "Expected '#{metadata["class"].name}##{m.name}' to have 1..2 parameters, got '#{m.args.size}'."
                end

                event_arg = m.args[0]

                # Validate the type restriction of the first parameter, if present
                event_arg.raise "Expected parameter #1 of '#{metadata["class"].name}##{m.name}' to have a type restriction of an 'AED::Event' instance, but it is not restricted." if event_arg.restriction.is_a?(Nop)
                event_arg.raise "Expected parameter #1 of '#{metadata["class"].name}##{m.name}' to have a type restriction of an 'AED::Event' instance, not '#{event_arg.restriction}'." if !(event_arg.restriction.resolve <= AED::Event)

                if dispatcher_arg = m.args[1]
                  event_arg.raise "Expected parameter #2 of '#{metadata["class"].name}##{m.name}' to have a type restriction of 'AED::EventDispatcherInterface', but it is not restricted." if dispatcher_arg.restriction.is_a?(Nop)
                  event_arg.raise "Expected parameter #2 of '#{metadata["class"].name}##{m.name}' to have a type restriction of 'AED::EventDispatcherInterface', not '#{dispatcher_arg.restriction}'." if !(dispatcher_arg.restriction.resolve <= AED::EventDispatcherInterface)
                end

                priority = m.annotation(AEDA::AsEventListener)["priority"] || 0

                unless priority.is_a? NumberLiteral
                  m.raise "Event listener method '#{metadata["class"].name}##{m.name}' expects a 'NumberLiteral' for its 'AEDA::AsEventListener#priority' field, but got a '#{priority.class_name.id}'."
                end

                listeners << {
                  event_arg.restriction.resolve.id,
                  m.args.size,
                  m.name.id,
                  "#{metadata["class"]}##{m.name.id}",
                  priority,
                  service_id,
                }
              end
            end
          %}

          {% for info in listeners %}
            {% event, count, method, name, priority, service_id = info %}

            {% if 1 == count %}
              dispatcher.add_callable(
                {{event}}.callable(priority: {{priority}}, name: {{name}}) { |event| self.{{service_id.id}}.{{method}} event.as({{event}}) },
              )
            {% else %}
              dispatcher.add_callable(
                {{event}}.callable(priority: {{priority}}, name: {{name}}) { |event, dispatcher| self.{{service_id.id}}.{{method}} event.as({{event}}), dispatcher },
              )
            {% end %}
          {% end %}

          dispatcher
        end
      {% end %}
    end
  end
end
