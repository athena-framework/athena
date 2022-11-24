abstract struct Athena::EventDispatcher::Callable
  include Comparable(self)

  getter event_class : AED::Event.class
  getter priority : Int32

  def initialize(
    @event_class : AED::Event.class,
    @priority : Int32
  ); end

  # :inherit:
  def <=>(other : AED::Callable) : Int32?
    other.priority <=> @priority
  end

  def call(event : AED::Event, dispatcher : AED::EventDispatcherInterface) : NoReturn
    raise "BUG: Invoked wrong `call` overload"
  end

  struct Event(E) < Athena::EventDispatcher::Callable
    @callback : E -> Nil

    def initialize(
      @callback : E -> Nil,
      priority : Int32 = 0,
      event_class : E.class = E
    )
      super event_class, priority
    end

    def_equals @event_class, @priority, @callback

    def call(event : E, dispatcher : AED::EventDispatcherInterface) : Nil
      @callback.call event
    end

    protected def copy_with(priority _priority = @priority) : self
      Event(E).new(
        callback: @callback,
        priority: _priority,
      )
    end
  end

  struct EventDispatcher(E) < Athena::EventDispatcher::Callable
    @callback : E, AED::EventDispatcherInterface -> Nil

    def initialize(
      @callback : E, AED::EventDispatcherInterface -> Nil,
      priority : Int32 = 0,
      event_class : E.class = E
    )
      super event_class, priority
    end

    def_equals @event_class, @priority, @callback

    def call(event : E, dispatcher : AED::EventDispatcherInterface) : Nil
      @callback.call event, dispatcher
    end

    protected def copy_with(priority _priority = @priority) : self
      EventDispatcher(E).new(
        callback: @callback,
        priority: _priority,
      )
    end
  end

  struct EventListenerInstance(I, E) < Athena::EventDispatcher::Callable
    getter instance : I

    @callback : Proc(E, Nil) | Proc(E, AED::EventDispatcherInterface, Nil)

    def initialize(
      @callback : Proc(E, Nil) | Proc(E, AED::EventDispatcherInterface, Nil),
      @instance : I,
      priority : Int32 = 0,
      event_class : E.class = E
    )
      super event_class, priority
    end

    def_equals @event_class, @priority, @callback, @instance

    def call(event : E, dispatcher : AED::EventDispatcherInterface) : Nil
      case cb = @callback
      in Proc(E, Nil)                                then cb.call event
      in Proc(E, AED::EventDispatcherInterface, Nil) then cb.call event, dispatcher
      end
    end

    protected def copy_with(priority _priority = @priority) : self
      EventListenerInstance(I, E).new(
        callback: @callback,
        instance: @instance,
        priority: _priority,
      )
    end
  end
end
