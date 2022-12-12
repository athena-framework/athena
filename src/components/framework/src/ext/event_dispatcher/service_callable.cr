# :nodoc:
struct Athena::Framework::EventDispatcher::Callable::Service(E) < Athena::EventDispatcher::Callable
  getter service_class : String
  getter method_name : String
  getter service_id : String

  @callback : E, AED::EventDispatcherInterface -> Nil

  def initialize(
    @callback : E, AED::EventDispatcherInterface -> Nil,
    @service_class : String,
    @method_name : String,
    @service_id : String,
    priority : Int32 = 0,
    event_class : E.class = E
  )
    super event_class, priority
  end

  # :nodoc:
  def_equals @event_class, @priority, @service_class, @service_id, @method_name, @callback

  # :nodoc:
  def call(event : E, dispatcher : AED::EventDispatcherInterface) : Nil
    @callback.call event, dispatcher
  end

  protected def copy_with(priority _priority = @priority) : self
    Athena::Framework::EventDispatcher::Callable::Service(E).new(
      callback: @callback,
      service_class: @service_class,
      method_name: @method_name,
      service_id: @service_id,
      priority: _priority,
    )
  end
end
