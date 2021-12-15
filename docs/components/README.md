This section will focus on how each component is integrated into Athena, as well an overview of the overall design of Athena.

At a high level Athena's job is *to interpret a request and create the appropriate response based on your application logic*. Conceptually this could be broken down into three steps:

1. Consume the request
2. Apply application logic to determine what the response should be
3. Return the response

Steps 1 and 3 are handled via Crystal's [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html), while step 2 is where Athena fits in.

## Powered By Events

Athena is an event based framework, meaning it emits various events via the [Event Dispatcher](event_dispatcher.md) component during the life-cycle of a request. These events are listened on internally in order to handle each request; custom listeners on these events can also be registered. The flow of a request, and the related events that are dispatched, is depicted below in a visual format:

![High Level Request Life-cycle Flow](../img/Athena.png)

### 1. Request Event

The very first event that is dispatched is the [ATH::Events::Request][Athena::Framework::Events::Request] event and can have a variety of listeners. The primary purpose of this event is to create an [ATH::Response][Athena::Framework::Response] directly, or to add information to the requests' attributes; a simple key/value store tied to request instance accessible via [ATH::Request#attributes][].

In some cases the listener may have enough information to return an [ATH::Response][Athena::Framework::Response] immediately. An example of this would be the [ATH::Listeners::CORS][Athena::Framework::Listeners::CORS] listener. If enabled it is able to return a `CORS` preflight response even before routing is invoked.

WARNING: If an [ATH::Response][Athena::Framework::Response] is returned at this stage, the flow of the request skips directly to the [response](#5-response-event) event. Future `Request` event listeners will not be invoked either.

Another use case for this event is populating additional data into the request's attributes; such as the locale or format of the request.

!!! example "Request event in Athena"
    This is the event that [ATH::Listeners::Routing][Athena::Framework::Listeners::Routing] listens on to determine which [ATH::Controller][Athena::Framework::Controller]/[ATH::Action][Athena::Framework::Action] pair should handle the request.

    See [ATH::Controller][Athena::Framework::Controller] for more details on routing.

### 2. Action Event

The next event to be dispatched is the [ATH::Events::Action][Athena::Framework::Events::Action] event, assuming a response was not already returned within the [request](#1-request-event) event. This event is dispatched after the related controller/action pair is determined, but before it is executed. This event is intended to be used when a listener requires information from the related [ATH::Action][Athena::Framework::Action]; such as reading custom annotations off of it via the [Config](config.md) component.

!!! example "Action event in Athena"
    This is the event that [ATH::Listeners::ParamConverter][Athena::Framework::Listeners::ParamConverter] and [ATH::Listeners::ParamFetcher][Athena::Framework::Listeners::ParamFetcher] listen on to apply custom conversion logic via an [ATH::ParamConverter][Athena::Framework::ParamConverter], or resolve request parameters such as [ATHA::QueryParam][Athena::Framework::Annotations::QueryParam]s.

### 3. Invoke the Controller Action

This next step is not an event, but a important concept within Athena nonetheless; executing the controller action related to the current request.

#### Argument Resolution

Before Athena can call the controller action, it first needs to determine what arguments, if any, should be passed to it. This is achieved via an [ATH::Arguments::ArgumentResolverInterface][Athena::Framework::Arguments::ArgumentResolverInterface] that facilitates gathering all the arguments. One or more [ATH::Arguments::Resolvers::ArgumentValueResolverInterface][Athena::Framework::Arguments::Resolvers::ArgumentValueResolverInterface] will then be used to resolve each specific argument's value.

The default algorithm is as follows:

1. Check the request's attributes for a key that matches the name of the argument; such as as a path param or something set via a listener (either built-in or custom)
1. Check if the type of the argument is [ATH::Request][], if so use the current request object
1. Check if the argument has a default value, or use `nil` if it is nilable
1. Raise an exception if an argument's value could be not resolved

Custom `ArgumentValueResolverInterface`s may be created & registered to extend this functionality.

TODO: An additional event could possibly be added after the arguments have been resolved, but before invoking the controller action.

#### Execute the Controller Action

The job of a controller action is to apply business/application logic to build a response for the related request; such as an HTML page, a JSON string, or anything else. How/what exactly this should be is up to the developer creating the application.

#### Handle the Response

The type of the value returned from the controller action determines what happens next. If the value is an [ATH::Response][Athena::Framework::Response], then it is used as is, skipping directly to the [response](#5-response-event) event. However, if the value is _NOT_ an [ATH::Response][Athena::Framework::Response], then the [view](#4-view-event) is dispatched (since Athena _needs_ an [ATH::Response][Athena::Framework::Response] in order to have something to send back to the client).

### 4. View Event

The [ATH::Events::View][Athena::Framework::Events::View] event is only dispatched when the controller action does _NOT_ return an [ATH::Response][Athena::Framework::Response]. The purpose of this event is to turn the controller action's return value into an [ATH::Response][Athena::Framework::Response].

An [ATH::View][] may be used to customize the response, e.g. setting a custom response status and/or adding additional headers; while keeping the controller action response data intact.

This event is intended to be used as a "View" layer; allowing scalar values/objects to be returned while listeners convert that value to the expected format (e.g. JSON, HTML, etc.). See the [negotiation](/components/negotiation) component for more information on this feature.

!!! example "View event in Athena"
    By default Athena will JSON serialize any non [ATH::Response][Athena::Framework::Response] values.

### 5. Response Event

The end goal of Athena is to return an [ATH::Response][Athena::Framework::Response] back to the client; which might be created within the [request](#1-request-event) event, returned from the related controller action, or set within the [view](#4-view-event) event. Regardless of how the response was created, the [ATH::Events::Response][Athena::Framework::Events::Response] event is dispatched directly after.

The intended use case for this event is to allow for modifying the response object in some manner. Common examples include: add/edit headers, add cookies, change/compress the response body.

### 6. Return the Response

The raw [HTTP::Server::Response](https://crystal-lang.org/api/HTTP/Server/Response.html) object is never directly exposed. The reasoning for this is to allow listeners to mutate the response before it is returned as mentioned in the [response](#5-response-event) event section. If the raw response object was exposed, whenever any data is written to it it'll immediately be sent to the client and the status/headers will be locked; as mentioned in the Crystal API docs:

> The response `#status` and `#headers` must be configured before writing the response body. Once response output is written, changing the `#status` and `#headers` properties has no effect.

Each [ATH::Response][Athena::Framework::Response] has a [ATH::Response::Writer][Athena::Framework::Response::Writer] instance that determines _how_ the response should be written to the raw response's IO. By default it is written directly, but can be customized via the [response](#5-response-event), such as for compression.

### 7. Terminate Event

The final event to be dispatched is the [ATH::Events::Terminate][Athena::Framework::Events::Terminate] event. This is event is dispatched _after_ the response has been sent to the user.

The intended use case for this event is to perform some "heavy" action after the user has received the response; as to not affect the response time of the request. E.x. queuing up emails or logs to be sent/written after a successful request.

### 8. Exception Handling

If an exception is raised at anytime while a request is being handled, the [ATH::Events::Exception][Athena::Framework::Events::Exception] is dispatched. The purpose of this event is to convert the exception into an [ATH::Response][Athena::Framework::Response]. This is globally handled via an [ATH::ErrorRendererInterface][Athena::Framework::ErrorRendererInterface], with the default being to JSON serialize the exception.

It is also possible to handle specific error states differently by registering multiple exception listeners to handle each case. An example of this could be to invoke some special logic only if the exception is of a specific type.

See the [error handling](../getting_started/README.md#error-handling) section in the getting started docs for more details on how error handling works in Athena.

## Orchestrated via Dependency Injection

All of the components have been designed with Dependency Injection (DI) in mind; even if it's not a requirement when using a component on its own. Athena itself makes heavy use of DI as the means to orchestrate all the dependencies that do/may exist in an application.

DI is used to allow for easier [testing](../getting_started/advanced_usage.md#testing), allowing for better reusability, and sharing state between types. See the [Dependency Injection](dependency_injection.md) component for more details on how to use it within Athena.
