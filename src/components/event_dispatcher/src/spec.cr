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
  #
  # ```
  # class MyEvent < AED::Event; end
  #
  # class OtherEvent < AED::Event; end
  #
  # dispatcher = AED::Spec::TracableEventDispatcher.new
  #
  # dispatcher.dispatch MyEvent.new
  # dispatcher.dispatch OtherEvent.new
  #
  # dispatcher.emitted_events # => [MyEvent, OtherEvent]
  # ```
  class TracableEventDispatcher < AED::EventDispatcher
    # Returns an array of each `AED::Event.class` that was dispatched via this dispatcher.
    getter emitted_events : Array(AED::Event.class) = [] of AED::Event.class

    # :inherit:
    def dispatch(event : AED::Event) : Nil
      @emitted_events << event.class

      super
    end
  end
end
