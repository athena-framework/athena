require "./event_dispatcher_interface"
require "./event"
require "./event_listener_interface"
require "./callable"

class Athena::EventDispatcher::EventDispatcher
  include Athena::EventDispatcher::EventDispatcherInterface

  @listeners = Hash(AED::Event.class, Array(AED::Callable)).new

  # Keeps track of event types that have already been sorted.
  @sorted = Set(AED::Event.class).new

  def listener(callable : AED::Callable) : AED::Callable
    self.add_callable callable
  end

  def listener(callable : AED::Callable, *, priority : Int32) : AED::Callable
    self.add_callable callable.copy_with priority: priority
  end

  def listener(listener : AED::EventListenerInterface) : Nil
    self.add_listener listener
  end

  private def add_listener(listener : T) : Nil forall T
    {% begin %}
      {% for m in T.methods.select &.annotation(AEDA::AsEventListener) %}
        {% ann = m.annotation AEDA::AsEventListener %}
        {% event = m.args[0].restriction || m.args[0].raise "No resetriction" %}

        {% if 1 == m.args.size %}
          self.add_callable(
            AED::Callable::EventListenerInstance(T, {{event}}).new(
              ->listener.{{m.name.id}}({{event}}),
              listener,
              {{ann[:priority] || 0}}
            )
          )
        {% else %}
          self.add_callable(
            AED::Callable::EventListenerInstance(T, {{event}}).new(
              ->listener.{{m.name.id}}({{event}}, AED::EventDispatcherInterface),
              listener,
              {{ann[:priority] || 0}}
            )
          )
        {% end %}
      {% end %}
    {% end %}
  end

  def listener(event_class : E.class, *, priority : Int32 = 0, &block : E, AED::EventDispatcherInterface ->) : AED::Callable forall E
    {% @def.args[0].raise "expected argument #1 to '#{@def.name}' to be #{AED::Event.class}, not #{E}" unless E <= AED::Event %}

    self.add_callable AED::Callable::EventDispatcher(E).new block, priority, event_class
  end

  protected def add_callable(callable : AED::Callable) : AED::Callable
    (@listeners[callable.event_class] ||= Array(Callable).new) << callable

    @sorted.delete callable.event_class

    callable
  end

  def has_listeners?(event_class : AED::Event.class | Nil = nil) : Bool
    if event_class
      return @listeners.has_key? event_class
    end

    @listeners.each_value.any? { |listeners| !listeners.empty? }
  end

  def remove_listener(listener : AED::EventListenerInterface) : Nil
    @listeners.each do |event_class, listeners|
      listeners.reject! { |l| l.is_a?(AED::Callable::EventListenerInstance) && l.instance == listener }

      @listeners.delete event_class if listeners.empty?
    end
  end

  def remove_listener(callable : AED::Callable) : Nil
    return unless (listeners = @listeners[callable.event_class]?)

    listeners.reject! do |c|
      c == callable
    end

    @listeners.delete callable.event_class if listeners.empty?
    @sorted.delete callable.event_class
  end

  def dispatch(event : AED::Event) : AED::Event
    # self.call_listeners event, self.listeners event.class
    self.call_listeners event, self.listeners event.class

    event
  end

  def listeners(for event_class : AED::Event.class) : Array(AED::Callable)
    return [] of AED::Callable unless @listeners.has_key? event_class

    unless @sorted.includes? event_class
      self.sort_listeners event_class
    end

    @listeners[event_class]
  end

  def listeners : Hash(AED::Event.class, Array(AED::Callable))
    @listeners.each_key do |ec|
      self.sort_listeners ec unless @sorted.includes? ec
    end

    @listeners
  end

  def listener_priority(event_class : AED::Event.class, callable : AED::Callable) : Int32?
    return unless (listeners = @listeners[event_class]?)

    listeners.each do |l|
      return l.priority if l == callable
    end
  end

  private def call_listeners(event : AED::Event, listeners : Array(AED::Callable)) : Nil
    stoppable = event.is_a? AED::StoppableEvent

    listeners.each do |listener|
      break if stoppable && !event.propagate?

      listener.call event, self
    end
  end

  private def sort_listeners(event_class : AED::Event.class) : Nil
    # Use stable sort to ensure callables with priority of `0` are invoked in the order they were inserted
    @listeners[event_class].sort!
    @sorted << event_class
  end
end
