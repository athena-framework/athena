Object-oriented code has helped a lot in ensuring code extensibility.
By having classes with well defined responsibilities, it becomes more flexible and easily extendable to modify their behavior.
However inheritance has its limits is not the best option when these modifications need to be shared between other modified subclasses.
Say for example you want to do something before and after a method is executed, without interfering with the other logic.

The `Athena::EventDispatcher` component is a [Mediator](https://en.wikipedia.org/wiki/Mediator_pattern) and [Observer](https://en.wikipedia.org/wiki/Observer_pattern) pattern event library.
This pattern allows creating very flexibly and truly extensible applications.

A good example of this is the [architecture](/getting_started/middleware#events) of the Athena Framework itself in how it uses `Athena::EventDispatcher` to dispatch events that then is able to notify all registered listeners for that event.
These listeners could then make any necessary modifications seamlessly without affecting the framework logic itself, or the other listeners.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-event_dispatcher:
    github: athena-framework/event-dispatcher
    version: ~> 0.2.0
```
## Usage

Usage of this component centers around [AED::EventDispatcherInterface][] implementations with the default being [AED::EventDispatcher][].
The event dispatcher  keeps track of the listeners on various [AED::Event][]s.
An event is nothing more than a plain old Crystal object that provides access to data related to the event.

```crystal
# Create a custom event that can be emitted when an order is placed.
class OrderPlaced < AED::Event
  getter order : Order

  def initialize(@order : Order); end
end
```

For simple use cases, listeners may be registered directly:

```crystal
dispatcher = AED::EventDispatcher.new

# Register a listener on our event directly with the dispatcher
dispatcher.listener OrderPlaced do |event|
  pp event.order
end
```

However having a dedicated type is usually the better practice.

```crystal
struct SendConfirmationListener
  include AED::EventListenerInterface

  @[AEDA::AsEventListener]
  def order_placed(event : OrderPlaced) : Nil
    # Send a confirmation email to the user
  end
end

dispatcher.listener SendConfirmationListener.new
```

In either case, the dispatcher can then be used to dispatch our event.

```crystal
# Assume this is a real object
record Order, id : String

event = OrderPlaced.new Order.new "order 1"

dispatcher.dispatch Order.new
# => Order(@id="order1")
```

WARNING: If using this component within the context of something that handles independent execution flows, such as a web framework, you will want there to be a dedicated dispatcher instance for each path.
This ensures that one flow will not leak state to any other flow, while still allowing flow specific mutations to be used.
Consider pairing this component with the [Athena::DependencyInjection](/DependencyInjection) component as a way to handle this.

## Learn More

* [Listener Priority][Athena::EventDispatcher::EventDispatcherInterface--listener-priority]
* [Stoppable][AED::StoppableEvent] events
* [Testing Abstractions][AED::Spec::TracableEventDispatcher]
