# Encapsulates everything required to represent an event listener.
# Including what event is being listened on, the callback itself, and its priority.
#
# Each subclass represents a specific "type" of listener.
# See each subclass for more information.
#
# TIP: These types can be manually instantiated and added via the related `AED::EventDispatcherInterface#listener(callable)` overload.
# This can be useful as a point of integration to other libraries, such as lazily instantiating listener instances.
#
# ### Name
#
# Each callable also has an optional *name* that can be useful for debugging to allow identifying a specific callable
# since there would be no way to tell apart two listeners on the same event, with the same priority.
#
# ```
# class MyEvent < AED::Event; end
#
# dispatcher = AED::EventDispatcher.new
#
# dispatcher.listener(MyEvent) { }
# dispatcher.listener(MyEvent, name: "block-listener") { }
#
# class MyListener
#   @[AEDA::AsEventListener]
#   def on_my_event(event : MyEvent) : Nil
#   end
# end
#
# dispatcher.listener MyListener.new
#
# dispatcher.listeners(MyEvent).map &.name # => ["unknown callable", "block-listener", "MyListener#on_my_event"]
# ```
#
# `AED::Callable::EventListenerInstance` instances registered via `AED::EventDispatcherInterface#listener(listener)` will automatically have a name including the
# method and listener class names in the format of `ClassName#method_name`.
abstract struct Athena::EventDispatcher::Callable
  include Comparable(self)

  # Returns what `AED::Event` class this callable represents.
  getter event_class : AED::Event.class

  # Returns the name of this callable.
  # Useful for debugging to identify a specific callable added from a block, or which method an `AED::Callable::EventListenerInstance` is associated with.
  getter name : String

  # Returns the [listener priority][Athena::EventDispatcher::EventDispatcherInterface--listener-priority] of this callable.
  getter priority : Int32

  def initialize(
    @event_class : AED::Event.class,
    name : String?,
    @priority : Int32,
  )
    @name = name || "unknown callable"
  end

  # :nodoc:
  def <=>(other : AED::Callable) : Int32?
    other.priority <=> @priority
  end

  # :nodoc:
  def call(event : AED::Event, dispatcher : AED::EventDispatcherInterface) : NoReturn
    raise "BUG: Invoked wrong `call` overload"
  end

  protected abstract def copy_with(priority _priority = @priority)

  # Represents a listener that only accepts the `AED::Event` instance.
  struct Event(E) < Athena::EventDispatcher::Callable
    @callback : E -> Nil

    def initialize(
      @callback : E -> Nil,
      priority : Int32 = 0,
      name : String? = nil,
      event_class : E.class = E,
    )
      super event_class, name, priority
    end

    # :nodoc:
    def_equals @event_class, @priority, @callback

    # :nodoc:
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

  # Represents a listener that accepts both the `AED::Event` instance and the `AED::EventDispatcherInterface` instance.
  # Such as when using [AED::EventDispatcherInterface#listener(event_class,*,priority,&)][Athena::EventDispatcher::EventDispatcherInterface#listener(callable,*,priority)], or the `AED::Event.callable` method.
  struct EventDispatcher(E) < Athena::EventDispatcher::Callable
    @callback : E, AED::EventDispatcherInterface -> Nil

    def initialize(
      @callback : E, AED::EventDispatcherInterface -> Nil,
      priority : Int32 = 0,
      name : String? = nil,
      event_class : E.class = E,
    )
      super event_class, name, priority
    end

    # :nodoc:
    def_equals @event_class, @priority, @callback

    # :nodoc:
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

  # Represents a dedicated type based listener using `AEDA::AsEventListener` annotations.
  struct EventListenerInstance(I, E) < Athena::EventDispatcher::Callable
    # Returns the listener instance this callable is associated with.
    getter instance : I

    @callback : Proc(E, Nil) | Proc(E, AED::EventDispatcherInterface, Nil)

    def initialize(
      @callback : Proc(E, Nil) | Proc(E, AED::EventDispatcherInterface, Nil),
      @instance : I,
      priority : Int32 = 0,
      name : String? = nil,
      event_class : E.class = E,
    )
      super event_class, name || "unknown #{@instance.class} method", priority
    end

    # :nodoc:
    def_equals @event_class, @priority, @callback, @instance

    # :nodoc:
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
