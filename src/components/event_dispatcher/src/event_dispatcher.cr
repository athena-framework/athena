require "./event_dispatcher_interface"
require "./event"
require "./event_listener_interface"

class Athena::EventDispatcher::EventDispatcher
  include Athena::EventDispatcher::EventDispatcherInterface

  alias OneType = Proc(Athena::EventDispatcher::Event, Nil)
  alias TwoType = Proc(Athena::EventDispatcher::Event, EventDispatcherInterface, Nil)
  alias Type = OneType | TwoType

  @listeners = Hash(AED::Event.class, Hash(Int32, Hash(UInt64, Type))).new
  @sorted = Hash(AED::Event.class, Array(Type)).new

  def listener(listener : T) : Nil forall T
    {% @def.raise "Cannot add non AED::EventListenerInterface" unless T <= AED::EventListenerInterface %}

    {% begin %}
      {% for m in T.methods.select &.annotation(AEDA::AsEventListener) %}
        {% ann = m.annotation AEDA::AsEventListener %}
        {% event = m.args[0].restriction || m.args[0].raise "No resetriction" %}

        {% if 1 == m.args.size %}
          # self.add_listener {{event}}, OneType.new { |event| ->listener.{{m.name.id}}({{event}}).call event.as({{event}}) }, priority: {{ann[:priority] || 0}}
          self.add_listener(
            {{event}},
            OneType.new { |event| ->listener.{{m.name.id}}({{event}}).call event.as({{event}}) },
            priority: {{ann[:priority] || 0}},
            origin: listener
          )
        {% else %}
          self.add_listener(
            {{event}},
            TwoType.new { |event, dispatcher| ->listener.{{m.name.id}}({{event}}, AED::EventDispatcherInterface).call event.as({{event}}), dispatcher },
            priority: {{ann[:priority] || 0}},
            origin: listener
          )
        {% end %}
      {% end %}
    {% end %}
  end

  def listener(event_class : T.class, *, priority : Int32 = 0, &block : T, AED::EventDispatcherInterface ->) : Nil forall T
    ((@listeners[event_class] ||= Hash(Int32, Hash(UInt64, Type)).new)[priority] ||= Hash(UInt64, Type).new)[block.hash] = TwoType.new do |event, dispatcher|
      block.call event.as(T), dispatcher
    end

    @sorted.delete event_class
  end

  protected def add_listener(event_class : AED::Event.class, block : Type, *, priority : Int32 = 0, origin = nil) : Nil
    ((@listeners[event_class] ||= Hash(Int32, Hash(UInt64, Type)).new)[priority] ||= Hash(UInt64, Type).new)[origin.try(&.hash) || block.hash] = block

    @sorted.delete event_class
  end

  def has_listeners?(event_class : AED::Event.class | Nil = nil) : Bool
    if event_class
      return @listeners.has_key?(event_class) && !@listeners[event_class].empty?
    end

    @listeners.each_value do |listeners|
      return true unless listeners.empty?
    end

    false
  end

  def remove_listener(listener : T) : Nil forall T
    {% @def.raise "Cannot remove events from a non AED::EventListenerInterface" unless T <= AED::EventListenerInterface %}

    {% begin %}
      {% for m in T.methods.select &.annotation(AEDA::AsEventListener) %}
        {% ann = m.annotation AEDA::AsEventListener %}
        {% event = m.args[0].restriction || m.args[0].raise "No resetriction" %}

        self.remove_listener {{event}}, listener.hash
      {% end %}
    {% end %}
  end

  def remove_listener(event_class : T.class, listener : Proc) forall T
    self.remove_listener event_class, listener.hash
  end

  private def remove_listener(event_class : AED::Event.class, hash : UInt64) : Nil
    return unless (listener_priorities = @listeners[event_class]?)
    return if listener_priorities.empty?

    listener_priorities.each do |priority, listeners|
      listeners.reject! do |k, v|
        k == hash
      end

      if listeners.empty?
        listener_priorities.delete priority
      end
    end
  end

  def dispatch(event : AED::Event) : AED::Event
    listeners = self.listeners event.class

    self.call_listeners event, listeners

    event
  end

  def listeners(for event_class : AED::Event.class) : Array(Type)
    return [] of Type if !@listeners.has_key?(event_class) || @listeners[event_class].empty?

    if !@sorted.has_key? event_class
      self.sort_listeners event_class
    end

    return @sorted[event_class]
  end

  def listeners : Hash(AED::Event.class, Array(Type))
    @listeners.each do |ec, listeners|
      if !@sorted.has_key? ec
        self.sort_listeners ec
      end
    end

    @sorted
  end

  def listener_priority(event_class : AED::Event.class, listener) : Int32?
    return if !@listeners.has_key?(event_class) || @listeners[event_class].empty?

    @listeners[event_class].each do |priority, listeners|
      listeners.each do |hash, l|
        return priority if hash == listener.hash
      end
    end
  end

  private def call_listeners(event : AED::Event, listeners : Array(Type)) : Nil
    stoppable = event.is_a? AED::StoppableEvent

    listeners.each do |listener|
      break if stoppable && !event.propagate?

      case listener
      in OneType then listener.call event
      in TwoType then listener.call event, self
      end
    end
  end

  private def sort_listeners(event_class : AED::Event.class) : Nil
    listeners = @listeners[event_class]
    @sorted[event_class] = [] of Type

    listeners
      .to_a
      .sort do |(p1, l1), (p2, l2)|
        p2 <=> p1
      end
      .each do |a, b|
        b.each_value do |l|
          @sorted[event_class] << l
        end
      end
  end
end
