module Athena::Framework::CompilerPasses::RegisterEventListenersPass
  include Athena::DependencyInjection::PreArgumentsCompilerPass

  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH["event_dispatcher"][:factory] = {"self".id, "get_event_dispatcher"}

          TAG_HASH[ATH::Listeners::TAG].each do |service_id|
            SERVICE_HASH[service_id][:visibility] = Visibility::INTERNAL
          end
        %}

        private def get_event_dispatcher
          dispatcher = AED::EventDispatcher.new

          {% for service_id in TAG_HASH[ATH::Listeners::TAG] %}
            {% metadata = SERVICE_HASH[service_id] %}

            {% listeners = [] of Nil %}

            # Changes made here should also be reflected within `AED::EventListenerInterface` overload within `AED::EventDispatcher`.
            {%
              class_listeners = metadata[:service].class.methods.select &.annotation(AEDA::AsEventListener)

              # Raise compile time error if a listener is defined as a class method.
              unless class_listeners.empty?
                class_listeners.first.raise "Event listener methods can only be defined as instance methods. Did you mean '#{metadata[:service].name}##{class_listeners.first.name}'?"
              end

              metadata[:service].methods.select(&.annotation(AEDA::AsEventListener)).each do |m|
                # Validate the parameters of each method.
                if (m.args.size < 1) || (m.args.size > 2)
                  m.raise "Expected '#{metadata[:service].name}##{m.name}' to have 1..2 parameters, got '#{m.args.size}'."
                end

                event_arg = m.args[0]

                # Validate the type restriction of the first parameter, if present
                event_arg.raise "Expected parameter #1 of '#{metadata[:service].name}##{m.name}' to have a type restriction of an 'AED::Event' instance, but it is not restricted." if event_arg.restriction.is_a?(Nop)
                event_arg.raise "Expected parameter #1 of '#{metadata[:service].name}##{m.name}' to have a type restriction of an 'AED::Event' instance, not '#{event_arg.restriction}'." if !(event_arg.restriction.resolve <= AED::Event)

                if dispatcher_arg = m.args[1]
                  event_arg.raise "Expected parameter #2 of '#{metadata[:service].name}##{m.name}' to have a type restriction of 'AED::EventDispatcherInterface', but it is not restricted." if dispatcher_arg.restriction.is_a?(Nop)
                  event_arg.raise "Expected parameter #2 of '#{metadata[:service].name}##{m.name}' to have a type restriction of 'AED::EventDispatcherInterface', not '#{dispatcher_arg.restriction}'." if !(dispatcher_arg.restriction.resolve <= AED::EventDispatcherInterface)
                end

                priority = m.annotation(AEDA::AsEventListener)[:priority] || 0

                unless priority.is_a? NumberLiteral
                  m.raise "Event listener method '#{metadata[:service].name}##{m.name}' expects a 'NumberLiteral' for its 'AEDA::AsEventListener#priority' field, but got a '#{priority.class_name.id}'."
                end

                listeners << {event_arg.restriction.resolve.id, m.args.size, m.name.id, priority}
              end
            %}

            {% for info in listeners %}
              {% event, count, method, priority = info %}

              {% if 1 == count %}
                dispatcher.add_callable(
                  {{event}}.callable(priority: {{priority}}) { |event| self.{{service_id.id}}.{{method}} event.as({{event}}) },
                )
              {% else %}
                dispatcher.add_callable(
                  {{event}}.callable(priority: {{priority}}) { |event, dispatcher| self.{{service_id.id}}.{{method}} event.as({{event}}), dispatcher },
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
