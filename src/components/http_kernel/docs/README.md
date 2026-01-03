The `Athena::HTTPKernel` component provides a structured process for converting an [AHTTP::Request](/HTTP/Request) into an [AHTTP::Response](/HTTP/Response) by dispatching events throughout the request lifecycle.
It serves as the foundation for the [Athena Framework](/getting_started), but can also be used standalone to build custom HTTP-based applications.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-http_kernel:
    github: athena-framework/http-kernel
    version: ~> 0.1.0
```

## Usage

The core of this component is [AHK::HTTPKernel][], which orchestrates the request handling process by dispatching a series of events.

### Request Lifecycle

When a request is handled, the following events are dispatched in order:

1. **[AHK::Events::Request][]** - Dispatched before anything else. Listeners can return a response early or modify the request.
2. **[AHK::Events::Action][]** - Dispatched after the action is determined but before it executes. Useful for accessing action metadata.
3. **[AHK::Events::View][]** - Dispatched if the action returns something other than a response. Listeners convert the return value into a response.
4. **[AHK::Events::Response][]** - Dispatched after a response is created. Listeners can modify the response before it's sent.
5. **[AHK::Events::Terminate][]** - Dispatched after the response is sent. Useful for "heavy" post-response processing.

If an exception is raised at any point, [AHK::Events::Exception][] is dispatched to allow converting the exception into a response.

### Basic Example

```crystal
require "athena-http_kernel"

# Create the required dependencies
event_dispatcher = AED::EventDispatcher.new
request_store = AHTTP::RequestStore.new

# Create a simple action resolver that always returns the same action.
# In practice, this would come from some sort of "controller".
class SimpleActionResolver
  include AHK::ActionResolverInterface

  def resolve(request : AHTTP::Request) : AHK::ActionBase?
    AHK::Action.new(
      action: Proc(typeof(Tuple.new), String).new { "Hello, World!" },
      parameters: Tuple.new,
      _return_type: String
    )
  end
end

# Create an argument resolver (no arguments needed for this simple example since it doesn't accept arguments)
argument_resolver = AHK::Controller::ArgumentResolver.new([] of AHK::Controller::ValueResolvers::Interface)

# Register a listener to convert the string return value into a response
event_dispatcher.listener AHK::Events::View do |event|
  event.response = AHTTP::Response.new(
    status: :ok,
    content: event.action_result.to_s
  )
end

# Register the error listener
error_renderer = AHK::ErrorRenderer.new(debug: true)
error_listener = AHK::Listeners::Error.new(error_renderer)
event_dispatcher.listener error_listener

# Create the kernel
kernel = AHK::HTTPKernel.new(
  event_dispatcher,
  request_store,
  argument_resolver,
  SimpleActionResolver.new
)

# Handle a request
request = AHTTP::Request.new("GET", "/")
response = kernel.handle(request)

response.status  # => HTTP::Status::OK
response.content # => "Hello, World!"

# Don't forget to terminate
kernel.terminate(request, response)
```

### HTTP Exceptions

The component provides a hierarchy of HTTP exceptions under [AHK::Exception][].
These exceptions automatically set the appropriate HTTP status code and can include custom headers.

```crystal
# Raise a 404 Not Found
raise AHK::Exception::NotFound.new "Resource not found"

# Raise a 400 Bad Request
raise AHK::Exception::BadRequest.new "Invalid input"

# Raise a 401 Unauthorized with WWW-Authenticate header
raise AHK::Exception::Unauthorized.new "Authentication required", "Bearer"

# Raise a 503 Service Unavailable with Retry-After header
raise AHK::Exception::ServiceUnavailable.new "Try again later", retry_after: 300
```

Non-HTTP exceptions are treated as `500 Internal Server Error` by default.

### Error Handling

The [AHK::Listeners::Error][] listener handles exceptions by converting them into responses via an [AHK::ErrorRendererInterface][].
The default [AHK::ErrorRenderer][] produces JSON responses:

```json
{
  "code": 404,
  "message": "Resource not found"
}
```

Custom error rendering can be implemented by creating a type that includes `AHK::ErrorRendererInterface`:

```crystal
class HTMLErrorRenderer
  include AHK::ErrorRendererInterface

  def render(exception : ::Exception) : AHTTP::Response
    status = exception.is_a?(AHK::Exception::HTTPException) ? exception.status : HTTP::Status::INTERNAL_SERVER_ERROR

    AHTTP::Response.new(
      status: status,
      headers: HTTP::Headers{"content-type" => "text/html"},
      body: "<h1>Error #{status.code}</h1><p>#{HTML.escape(exception.message || "Unknown error")}</p>"
    )
  end
end
```

### Value Resolvers

Value resolvers determine how arguments are passed to controller actions.
The component includes several built-in resolvers:

- [AHK::Controller::ValueResolvers::Request][] - Injects the current request if the parameter type is `AHTTP::Request`
- [AHK::Controller::ValueResolvers::RequestAttribute][] - Resolves values from request attributes (e.g., route parameters)
- [AHK::Controller::ValueResolvers::DefaultValue][] - Uses the parameter's default value or `nil` if nilable

Custom resolvers can be created by implementing [AHK::Controller::ValueResolvers::Interface][]:

```crystal
struct CurrentTimeResolver
  include AHK::Controller::ValueResolvers::Interface

  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata) : Time?
    return unless parameter.type == Time
    Time.utc
  end
end
```

## Integration with Athena Framework

When used with the [Athena Framework](/getting_started), the HTTPKernel is automatically configured with:

- Dependency injection for all components
- The routing component for URL matching
- Additional value resolvers for query parameters, request body deserialization, enums, UUIDs, and time parsing
- View handling for content negotiation and serialization
- CORS support

See the [Getting Started](/getting_started) guide for full framework documentation.

## Learn More

- [Middleware Architecture](/getting_started/middleware) - Detailed explanation of the event-driven request lifecycle
- [Error Handling](/getting_started/error_handling) - Working with HTTP exceptions
- [AHK::HTTPKernel][] - API documentation for the kernel
- [AHK::Events][] - All available lifecycle events
- [AHK::Exception][] - Available HTTP exception types
