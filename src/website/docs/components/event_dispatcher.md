As mentiond in the [architecture](README.md) section, Athena is an event based framework utilizing the [Event Dispatcher][Athena::EventDispatcher] component.

## Basic Usage

An event listener is defined by registering a service that includes [AED::EventListenerInterface][Athena::EventDispatcher::EventListenerInterface]. The type should also define a `self.subscribed_events` method that represents what [events][Athena::Framework::Events] it should be listening on.

```crystal
require "athena"

@[ADI::Register]
class CustomListener
  include AED::EventListenerInterface

  # Specify that we want to listen on the `Response` event.
  # The value of the hash represents this listener's priority;
  # the higher the value the sooner it gets executed.
  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{ATH::Events::Response => 25}
  end

  def call(event : ATH::Events::Response, dispatcher : AED::EventDispatcherInterface) : Nil
    event.response.headers["FOO"] = "BAR"
  end
end

class ExampleController < ATH::Controller
  get "/" do
    "Hello World"
  end
end

ATH.run

# GET / # => Hello World (with `FOO => BAR` header)
```

TIP: A single event listener may listen on multiple events. Instance variables can be used to share state between the events.

WARNING: The "type" of the listener has an effect on its behavior!
When a `struct` service is retrieved or injected into a type, it will be a copy of the one in the SC (passed by value).
This means that changes made to it in one type, will *NOT* be reflected in other types.
A `class` service on the other hand will be a reference to the one in the SC. This allows it to share state between services.

## Custom Events

Custom events can also be defined and dispatched; either within a listener, or in another service by injecting [AED::EventDispatcherInterface][Athena::EventDispatcher::EventDispatcherInterface] and calling `#dispatch`.

```crystal
require "athena"

# Define a custom event
class MyEvent < AED::Event
  property value : Int32
  
  def initialize(@value : Int32); end
end

# Define a listener that listens our the custom event.
@[ADI::Register]
class CustomEventListener
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{MyEvent => 0}
  end

  def call(event : MyEvent, dispatcher : AED::EventDispatcherInterface) : Nil
    event.value *= 10
  end
end

# Register a controller as a service,
# injecting the event dispatcher to handle processing our value.
@[ADI::Register(public: true)]
class ExampleController < ATH::Controller
  def initialize(@event_dispatcher : AED::EventDispatcherInterface); end
  
  @[ATHA::Get("/:value")]
  def get_value(value : Int32) : Int32
    event = MyEvent.new value
    
    @event_dispatcher.dispatch event
    
    event.value
  end
end

ATH.run

# GET /10 # => 100
```
