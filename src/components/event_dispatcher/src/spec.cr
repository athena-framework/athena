require "spec"

# A set of testing utilities/types to aid in testing `Athena::EventDispatcher` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec".
# require "athena-event_dispatcher/spec"
# ```
module Athena::EventDispatcher::Spec
  # Test implementation of `AED::EventDispatcherInterface` that keeps track of the events that were dispatched.
  class TracableEventDispatcher < AED::EventDispatcher
    getter emitted_events : Array(AED::Event.class) = [] of AED::Event.class

    def self.new
      new [] of AED::EventListenerInterface
    end

    def dispatch(event : AED::Event) : Nil
      @emitted_events << event.class

      super
    end
  end
end
