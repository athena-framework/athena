require "./event_dispatcher_interface"
require "./event"
require "./event_listener_interface"

class Athena::EventDispatcher::EventDispatcher
  include Athena::EventDispatcher::EventDispatcherInterface

  # Mapping of `Event` types to `EventListener` listening on that event.
  @events : Hash(Event.class, Array(EventListener))

  # Keep track of which events have been sorted so that listener arrays can be sorted only when needed.
  @sorted : Set(Event.class) = Set(Event.class).new

  # Initializes `self` with the provided *listeners*.
  #
  # This overload is mainly intended for DI or to manually
  # configure the listeners that should be listened on.
  def initialize(listeners : Array(AED::EventListenerInterface))
    # Initialize the event_hash, with a default size of the number of event subclasses. Add one to account for `Event` itself.
    @events = Hash(AED::Event.class, Array(AED::EventListener)).new {{Event.all_subclasses.size + 1}} { raise "Bug: Accessed missing event type" }

    # Iterate over event classes to "register" them with the events hash
    {% for event in AED::Event.all_subclasses %}
      {% raise "Event '#{event.name}' cannot be generic" if event.type_vars.size >= 1 %}
      {% unless event.abstract? %}
        # Initialize each event to an empty array with a default size of the number of total listeners
        @events[{{event.id}}] = Array(AED::EventListener).new {{AED::EventListenerInterface.includers.size}}
      {% end %}
    {% end %}

    listeners.each do |listener|
      listener.class.subscribed_events.each do |event, priority|
        add_listener event, listener, priority
      end
    end
  end

  # Initializes `self` automatically via macros.  This overload is mainly intended for
  # use cases where the listener types don't have any dependencies, and/or all listeners should listen.
  def self.new
    new {{AED::EventListenerInterface.includers.map { |listener| "#{listener.id}.new".id }}}
  end

  # :inherit:
  def add_listener(event : AED::Event.class, listener : AED::EventListenerType, priority : Int32 = 0) : Nil
    @events[event] << AED::EventListener.new listener, priority
    @sorted.delete event
  end

  # :inherit:
  def dispatch(event : AED::Event) : Nil
    listeners(event.class).each do |listener|
      return if event.is_a?(AED::StoppableEvent) && !event.propagate?

      listener.call event, self
    end
  end

  # :inherit:
  def listeners(event : AED::Event.class | Nil = nil) : Array(AED::EventListener)
    if event
      sort(event) unless @sorted.includes? event

      return @events[event]
    end

    @events.each do |ev, _listeners|
      sort(ev) unless @sorted.includes? event
    end

    @events.values.flatten
  end

  # :inherit:
  def listener_priority(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Int32?
    return nil unless has_listeners? event

    @events[event].find(&.listener.class.==(listener)).try &.priority
  end

  # :inherit:
  def has_listeners?(event : AED::Event.class | Nil = nil) : Bool
    return !@events[event].empty? if event

    @events.values.any? { |listener_arr| !listener_arr.empty? }
  end

  # :inherit:
  def remove_listener(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Nil
    @events[event].reject! &.listener.class.==(listener)
  end

  # :inherit:
  def remove_listener(event : AED::Event.class, listener : AED::EventListenerType) : Nil
    @events[event].reject! &.==(listener)
  end

  private def sort(event : AED::Event.class) : Nil
    @events[event].sort_by!(&.priority).reverse!
  end
end
