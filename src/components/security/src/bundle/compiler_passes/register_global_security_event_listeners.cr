# :nodoc:
#
# Registers the listeners of the `event_dispatcher` service that listen to `ASEC::Events` with the event dispatcher of each firewall too, as those events are dispatched via the latter.
# Runs after `ADI::ServiceContainer::RegisterEventListeners` registered the listeners.
module Athena::Security::Bundle::CompilerPasses::RegisterGlobalSecurityEventListeners
  macro included
    macro finished
      {% verbatim do %}
        {%
          if event_dispatcher = SERVICE_HASH["event_dispatcher"]
            firewall_dispatchers = [] of Nil

            CONFIG["security"]["firewalls"].to_a.each do |(name, firewall)|
              if name.stringify != "__nil" && firewall["security"]
                firewall_dispatchers << SERVICE_HASH["athena_security_event_dispatcher_#{name}"]
              end
            end

            event_dispatcher["calls"].each do |(method, args)|
              if method == "listener"
                klass = SERVICE_HASH[args[0].stringify]["class"]

                listens_to_security_events = klass.methods.any? do |m|
                  m.annotation(AEDA::AsEventListener) &&
                    (event_arg = m.args[0]) &&
                    !event_arg.restriction.is_a?(Nop) &&
                    event_arg.restriction.resolve.name.starts_with?("Athena::Security::Events::")
                end

                if listens_to_security_events
                  firewall_dispatchers.each do |firewall_dispatcher|
                    firewall_dispatcher["calls"] << {"listener", args}
                  end
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
