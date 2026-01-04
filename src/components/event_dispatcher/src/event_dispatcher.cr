require "./event_dispatcher_interface"
require "./event"
require "./callable"

# Default implementation of `AED::EventDispatcherInterface`.
class Athena::EventDispatcher::EventDispatcher
  include Athena::EventDispatcher::EventDispatcherInterface

  @listeners = Hash(ACTR::EventDispatcher::Event.class, Array(AED::Callable)).new

  # Keeps track of event types that have already been sorted.
  @sorted = Set(ACTR::EventDispatcher::Event.class).new

  # :inherit:
  def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
    self.call_listeners event, self.listeners event.class

    event
  end

  # :inherit:
  def has_listeners? : Bool
    @listeners.each_value.any? { |listeners| !listeners.empty? }
  end

  # :inherit:
  def has_listeners?(event_class : ACTR::EventDispatcher::Event.class) : Bool
    @listeners.has_key? event_class
  end

  # :inherit:
  def listener(callable : AED::Callable) : AED::Callable
    self.add_callable callable
  end

  # :inherit:
  def listener(callable : AED::Callable, *, priority : Int32) : AED::Callable
    self.add_callable callable.copy_with priority: priority
  end

  # :inherit:
  def listener(event_class : E.class, *, priority : Int32 = 0, name : String? = nil, &block : E, AED::EventDispatcherInterface -> Nil) : AED::Callable forall E
    {%
      unless E <= ACTR::EventDispatcher::Event
        @def.args[0].raise "expected argument #1 to '#{@def.name}' to be #{ACTR::EventDispatcher::Event.class}, not #{E}."
      end
    %}

    self.add_callable AED::Callable::EventDispatcher(E).new block, priority, name
  end

  # :inherit:
  def listener(listener : T) : Nil forall T
    {% begin %}
      {% listeners = [] of Nil %}

      {%
        class_listeners = T.class.methods.select &.annotation(AEDA::AsEventListener)

        # Raise compile time error if a listener is defined as a class method.
        unless class_listeners.empty?
          class_listeners.first.raise "Event listener methods can only be defined as instance methods. Did you mean '#{T.name}##{class_listeners.first.name}'?"
        end

        T.methods.select(&.annotation(AEDA::AsEventListener)).each do |m|
          # Validate the parameters of each method.
          if (m.args.size < 1) || (m.args.size > 2)
            m.raise "Expected '#{T.name}##{m.name}' to have 1..2 parameters, got '#{m.args.size}'."
          end

          event_arg = m.args[0]

          # Validate the type restriction of the first parameter, if present
          if event_arg.restriction.is_a?(Nop)
            event_arg.raise "'#{T.name}##{m.name}': event parameter must have a type restriction of an 'Athena::Contracts::EventDispatcher::Event' instance."
          end

          if !(event_arg.restriction.resolve <= ACTR::EventDispatcher::Event)
            event_arg.raise "'#{T.name}##{m.name}': event parameter must have a type restriction of an 'Athena::Contracts::EventDispatcher::Event' instance, not '#{event_arg.restriction}'."
          end

          if dispatcher_arg = m.args[1]
            if dispatcher_arg.restriction.is_a?(Nop)
              dispatcher_arg.raise "'#{T.name}##{m.name}': dispatcher parameter must have a type restriction of 'AED::EventDispatcherInterface'."
            end

            if !(dispatcher_arg.restriction.resolve <= AED::EventDispatcherInterface)
              dispatcher_arg.raise "'#{T.name}##{m.name}': dispatcher parameter must have a type restriction of 'AED::EventDispatcherInterface', not '#{dispatcher_arg.restriction}'."
            end
          end

          priority = m.annotation(AEDA::AsEventListener)[:priority] || 0

          unless priority.is_a? NumberLiteral
            m.raise "Event listener method '#{T.name}##{m.name}' expects a 'NumberLiteral' for its 'AEDA::AsEventListener#priority' field, but got a '#{priority.class_name.id}'."
          end

          listeners << {event_arg.restriction.resolve.id, m.args.size, m.name.id, priority}
        end
      %}

      {% for info in listeners %}
        {% event, count, method, priority = info %}

        {% if 1 == count %}
          self.add_callable(
            AED::Callable::EventListenerInstance(T, {{event}}).new(
              ->listener.{{method}}({{event}}),
              listener,
              {{priority}},
              "{{T}}##{{{method.stringify}}}"
            )
          )
        {% else %}
          self.add_callable(
            AED::Callable::EventListenerInstance(T, {{event}}).new(
              ->listener.{{method}}({{event}}, AED::EventDispatcherInterface),
              listener,
              {{priority}},
              "{{T}}##{{{method.stringify}}}"
            )
          )
        {% end %}
      {% end %}
    {% end %}
  end

  protected def add_callable(callable : AED::Callable) : AED::Callable
    (@listeners[callable.event_class] ||= Array(Callable).new) << callable

    @sorted.delete callable.event_class

    callable
  end

  # :inherit:
  def listeners : Hash(ACTR::EventDispatcher::Event.class, Array(AED::Callable))
    @listeners.each_key do |ec|
      self.sort_listeners ec unless @sorted.includes? ec
    end

    @listeners
  end

  # :inherit:
  def listeners(for event_class : ACTR::EventDispatcher::Event.class) : Array(AED::Callable)
    return [] of AED::Callable unless @listeners.has_key? event_class

    unless @sorted.includes? event_class
      self.sort_listeners event_class
    end

    @listeners[event_class]
  end

  # :inherit:
  def remove_listener(callable : AED::Callable) : Nil
    return unless listeners = @listeners[callable.event_class]?

    listeners.reject! { |c| c == callable }

    @listeners.delete callable.event_class if listeners.empty?
    @sorted.delete callable.event_class
  end

  # :inherit:
  def remove_listener(listener : T) : Nil forall T
    @listeners.each do |event_class, listeners|
      listeners.reject! { |l| l.is_a?(AED::Callable::EventListenerInstance) && l.instance == listener }

      @listeners.delete event_class if listeners.empty?
    end
  end

  private def call_listeners(event : ACTR::EventDispatcher::Event, listeners : Array(AED::Callable)) : Nil
    listeners.each do |listener|
      break if event.is_a?(ACTR::EventDispatcher::StoppableEvent) && !event.propagate?

      listener.call event, self
    end
  end

  private def sort_listeners(event_class : ACTR::EventDispatcher::Event.class) : Nil
    # Use stable sort to ensure callables with priority of `0` are invoked in the order they were inserted
    @listeners[event_class].sort!
    @sorted << event_class
  end
end
