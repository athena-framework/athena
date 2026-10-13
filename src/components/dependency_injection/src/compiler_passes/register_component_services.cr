# :nodoc:
#
# Registers the services of the other Athena components that are present, along with aliases to their interfaces:
#
# * `clock` - `ACLK::Interface`, if the [Clock](/Clock/) component is present
# * `event_dispatcher` - `AED::EventDispatcherInterface` and `ACTR::EventDispatcher::Interface`, if the [Event Dispatcher](/EventDispatcher/) component is present
#
# The aliases are set before `ADI::AsAlias` annotations are processed, so that applications may replace them.
module Athena::DependencyInjection::ServiceContainer::RegisterComponentServices
  macro included
    macro finished
      {% verbatim do %}
        {%
          if @top_level.has_constant?("ACLK")
            SERVICE_HASH[clock_id = "clock"] = {
              class: Athena::Clock,
            }

            ALIASES[Athena::Clock::Interface] = [
              {id: clock_id, public: false},
            ]
          end

          if @top_level.has_constant?("AED")
            SERVICE_HASH[event_dispatcher_id = "event_dispatcher"] = {
              class:  Athena::EventDispatcher::EventDispatcher,
              public: true,
            }

            ALIASES[Athena::EventDispatcher::EventDispatcherInterface] = [
              {id: event_dispatcher_id, public: false},
            ]

            ALIASES[Athena::Contracts::EventDispatcher::Interface] = [
              {id: event_dispatcher_id, public: false},
            ]
          end
        %}
      {% end %}
    end
  end
end
