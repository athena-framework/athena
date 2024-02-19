Athena does not have any other dependencies outside of [Crystal](https://crystal-lang.org) and [Shards](https://crystal-lang.org/reference/the_shards_command/index.html).
It is designed in such a way to be non-intrusive and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  athena:
    github: athena-framework/framework
    version: ~> 0.18.0
```

Run `shards install`. This will install the framework component and its required component dependencies.

TIP: Check out the [skeleton](https://github.com/athena-framework/skeleton) template repository to get up and running quickly.

## Usage

Athena Framework has a goal of being easy to start using for simple use cases, while still allowing flexibility/customizability for larger more complex use cases.

### Routing

The Athena Framework is a MVC based framework, as such, the logic to handle a given route is defined in an [ATH::Controller][] class.

```crystal
require "athena"

# Define a controller
class ExampleController < ATH::Controller
  # Define an action to handle the related route
  @[ARTA::Get("/")]
  def index : String
    "Hello World"
  end

  # The macro DSL can also be used
  get "/" do
    "Hello World"
  end
end

# Run the server
ATH.run

# GET / # => Hello World
```

Routing is handled via the [Athena::Routing][] component. It provides a flexible and robust foundation for handling determining which route should match a given request.
It includes regex based requirements, host name restrictions, and priorities to allow defining routes with parameters at the same location among others.
See the routing [documentation](../architecture/routing.md) for more information.

Controllers are simply classes and routes are simply methods. Controllers and actions can be documented/tested as you would any Crystal class/method.

### Route Parameters

Arguments are converted to their expected types if possible, otherwise an error response is automatically returned.
The values are provided directly as method arguments, thus preventing the need for `env.params.url["name"]` and any boilerplate related to it.
Just like normal method arguments, default values can be defined.
The method's return type adds some type safety to ensure the expected value is being returned.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Get("/add/{value1}/{value2}")]
  @[ATHA::QueryParam("negative")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end
end

ATH.run

# GET /add/2/3               # => 5
# GET /add/5/5?negative=true # => -10
# GET /add/foo/12            # => {"code":400,"message":"Required parameter 'value1' with value 'foo' could not be converted into a valid 'Int32'"}
```

TIP: For more complex conversions, consider creating a [Value Resolver][ATHR::Interface] to encapsulate the logic.

[ATHA::QueryParam][] and [ATHA::RequestParam][]s are defined via annotations and map directly to the method's arguments. See the related annotation docs for more information.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Get("/")]
  @[ATHA::QueryParam("page", requirements: /\d{2}/)]
  def index(page : Int32) : Int32
    page
  end
end

ATH.run

# GET /          # => {"code":422,"message":"Parameter 'page' of value '' violated a constraint: 'This value should not be null.'\n"}
# GET /?page=10  # => 10
# GET /?page=bar # => {"code":400,"message":"Required parameter 'page' with value 'bar' could not be converted into a valid 'Int32'."}
# GET /?page=5   # => {"code":422,"message":"Parameter 'page' of value '5' violated a constraint: 'Parameter 'page' value does not match requirements: (?-imsx:^(?-imsx:\\d{2})$)'\n"}
```

#### Request Parameter

Restricting an action argument to [ATH::Request][] will provide the raw request object. This can be useful to access data directly off the request object, such as consuming the request's body.
This approach is fine for simple or one-off endpoints.

TIP: Check out [ATHR::RequestBody][] for a better way to handle this.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Post("/data")]
  def data(request : ATH::Request) : String
    raise ATH::Exceptions::BadRequest.new "Request body is empty." unless body = request.body

    JSON.parse(body).as_h["name"].as_s
  end
end

ATH.run

# POST /data body: {"id":1,"name":"Jim"} # => Jim
```

#### Returning Raw Data

An [ATH::Response][] can be used to fully customize the response; such as returning a specific status code, or adding some one-off headers.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  # A GET endpoint returning an `ATH::Response`.
  # Can be used to return raw data, such as HTML or CSS etc, in a one-off manner.
  @[ARTA::Get("/index")]
  def index : ATH::Response
    ATH::Response.new(
      "<h1>Welcome to my website!</h1>",
      headers: HTTP::Headers{"content-type" => MIME.from_extension(".html")}
    )
  end
end

ATH.run

# GET /index # => "<h1>Welcome to my website!</h1>"
```

An [ATH::Events::View][] is emitted if the returned value is _NOT_ an [ATH::Response][]. By default, non [ATH::Response][]s are JSON serialized.
However, this event can be listened on to customize how the value is serialized.

##### Streaming Response

By default `ATH::Response` content is written all at once to the response's `IO`. However in some cases the content may be too large to fit into memory. In this case an [ATH::StreamedResponse][] may be used to stream the content back to the client.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ARTA::Get(path: "/users")]
  def users : ATH::Response
    ATH::StreamedResponse.new headers: HTTP::Headers{"content-type" => "application/json; charset=UTF-8"} do |io|
      User.all.to_json io
    end
  end
end

ATH.run

# GET /athena/users" # => [{"id":1,...},...]
```

#### Returning Files

An [ATH::BinaryFileResponse][] may be used to return static files/content. This response type handles caching, partial requests, and setting the relevant headers.
The Athena Framework also supports downloading of dynamically generated content by using an [ATH::Response][] with the [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header. [ATH::HeaderUtils.make_disposition][Athena::Framework::HeaderUtils.make_disposition(disposition,filename,fallback_filename)] can be used to easily build the header.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ARTA::Get(path: "/data/export")]
  def data_export : ATH::Response
    # ...

    ATH::Response.new(
      content,
      headers: HTTP::Headers{
        "content-disposition" => ATH::HeaderUtils.make_disposition(:attachment, "data.csv"),
        "content-type" => MIME.from_extension(".csv")
      }
    )
  end
end

ATH.run
```

##### Static Files

Static files can also be served from an Athena application.
This can be achieved by combining an [ATH::BinaryFileResponse][Athena::Framework::BinaryFileResponse] with the [request](../architecture/README.md#1-request-event) event;
checking if the request's path represents a file/directory within the application's public directory and returning the file if so.

```crystal
# Register a request event listener to handle returning static files.
@[ADI::Register]
struct StaticFileListener
  include AED::EventListenerInterface

  # This could be parameter if the directory changes between environments.
  private PUBLIC_DIR = Path.new("public").expand

  # Run this listener with a very high priority so it is invoked before any application logic.
  @[AEDA::AsEventListener(priority: 256)]
  def on_request(event : ATH::Events::Request) : Nil
    # Fallback if the request method isn't intended for files.
    # Alternatively, a 405 could be thrown if the server is dedicated to serving files.
    return unless event.request.method.in? "GET", "HEAD"

    original_path = event.request.path
    request_path = URI.decode original_path

    # File path cannot contains '\0' (NUL).
    if request_path.includes? '\0'
      raise ATH::Exceptions::BadRequest.new "File path cannot contain NUL bytes."
    end

    request_path = Path.posix request_path
    expanded_path = request_path.expand "/"

    file_path = PUBLIC_DIR.join expanded_path.to_kind Path::Kind.native

    is_dir = Dir.exists? file_path
    is_dir_path = original_path.ends_with? '/'

    event.response = if request_path != expanded_path || is_dir && !is_dir_path
                       redirect_path = expanded_path
                       if is_dir && !is_dir_path
                         redirect_path = expanded_path.join ""
                       end

                       # Request is a directory but acting as a file,
                       # redirect to the actual directory URL.
                       ATH::RedirectResponse.new redirect_path
                     elsif File.file? file_path
                       ATH::BinaryFileResponse.new file_path
                     else
                       # Nothing to do.
                       return
                     end
  end
end
```

### URL Generation

A common use case, especially when rendering `HTML`, is generating links to other routes based on a set of provided parameters.

```crystal
require "athena"

class ExampleController < ATH::Controller
  # Define a route to redirect to, explicitly naming this route `add`.
  # The default route name is controller + method down snake-cased; e.x. `example_controller_add`.
  @[ARTA::Get("/add/{value1}/{value2}", name: "add")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end

  # Define a route that redirects to the `add` route with fixed parameters.
  @[ARTA::Get("/")]
  def redirect : ATH::RedirectResponse
    # Generate a link to the other route.
    url = self.generate_url "add", value1: 8, value2: 2

    url # => /add/8/2

    # Redirect to the user to the generated url.
    self.redirect url

    # Or could have used a method that does both
    self.redirect_to_route "add", value1: 8, value2: 2
  end
end

ATH.run

# GET / # => 10
```

NOTE: URL generation has some gotchas when used outside of a request context. See the routing [documentation](../architecture/routing.md) for more information.

See [ART::Generator::Interface][] in the API Docs for more details.

### Error Handling

Exception handling in the Athena Framework is similar to exception handling in any Crystal program, with the addition of a new unique exception type, [ATH::Exceptions::HTTPException][].
Custom `HTTP` errors can also be defined by inheriting from [ATH::Exceptions::HTTPException][] or a child type.
A use case for this could be allowing additional data/context to be included within the exception.

Non [ATH::Exceptions::HTTPException][] exceptions are represented as a `500 Internal Server Error`.

When an exception is raised, the framework emits the [ATH::Events::Exception][] event to allow an opportunity for it to be handled.
By default these exceptions will return a `JSON` serialized version of the exception, via [ATH::ErrorRenderer][], that includes the message and code; with the proper response status set.
If the exception goes unhandled, i.e. no listener sets an [ATH::Response][] on the event, then the request is finished and the exception is re-raised.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Get("/divide/{num1}/{num2}")]
  def divide(num1 : Int32, num2 : Int32) : Int32
    num1 // num2
  end

  @[ARTA::Get("/divide_rescued/{num1}/{num2}")]
  def divide_rescued(num1 : Int32, num2 : Int32) : Int32
    num1 // num2
    # Rescue a non `ATH::Exceptions::HTTPException`
  rescue ex : DivisionByZeroError
    # in order to raise an `ATH::Exceptions::HTTPException` to provide a better error message to the client.
    raise ATH::Exceptions::BadRequest.new "Invalid num2:  Cannot divide by zero"
  end
end

ATH.run

# GET /divide/10/0          # => {"code":500,"message":"Internal Server Error"}
# GET /divide_rescued/10/0  # => {"code":400,"message":"Invalid num2:  Cannot divide by zero"}
# GET /divide_rescued/10/10 # => 1
```

### Logging

Logging is handled via Crystal's [Log](https://crystal-lang.org/api/Log.html) module. Athena Framework logs when a request matches a controller action, as well as any exception. This of course can be augmented with additional application specific messages.

```bash
2022-01-08T20:44:18.134423Z   INFO - athena.routing: Server has started and is listening at http://0.0.0.0:3000
2022-01-08T20:44:19.773376Z   INFO - athena.routing: Matched route 'example_controller_divide' -- route: "example_controller_divide", route_parameters: {"_route" => "example_controller_divide", "_controller" => "ExampleController#divide", "num1" => "10", "num2" => "0"}, request_uri: "/divide/10/0", method: "GET"
2022-01-08T20:44:19.892748Z  ERROR - athena.routing: Uncaught exception #<DivisionByZeroError:Division by 0> at /usr/lib/crystal/int.cr:141:7 in 'check_div_argument'
Division by 0 (DivisionByZeroError)
  from /usr/lib/crystal/int.cr:141:7 in 'check_div_argument'
  from /usr/lib/crystal/int.cr:105:5 in '//'
  from src/components/framework/src/athena.cr:206:5 in 'divide'
  from src/components/framework/src/ext/routing/annotation_route_loader.cr:8:5 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'execute'
  from src/components/framework/src/route_handler.cr:76:16 in 'handle_raw'
  from src/components/framework/src/route_handler.cr:19:5 in 'handle'
  from src/components/framework/src/athena.cr:161:27 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'process'
  from /usr/lib/crystal/http/server.cr:515:5 in 'handle_client'
  from /usr/lib/crystal/http/server.cr:468:13 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'run'
  from /usr/lib/crystal/fiber.cr:98:34 in '->'
  from ???

2022-01-08T20:45:10.803001Z   INFO - athena.routing: Matched route 'example_controller_divide_rescued' -- route: "example_controller_divide_rescued", route_parameters: {"_route" => "example_controller_divide_rescued", "_controller" => "ExampleController#divide_rescued", "num1" => "10", "num2" => "0"}, request_uri: "/divide_rescued/10/0", method: "GET"
2022-01-08T20:45:10.923945Z   WARN - athena.routing: Uncaught exception #<Athena::Framework::Exceptions::BadRequest:Invalid num2:  Cannot divide by zero> at src/components/framework/src/athena.cr:215:5 in 'divide_rescued'
Invalid num2:  Cannot divide by zero (Athena::Framework::Exceptions::BadRequest)
  from src/components/framework/src/athena.cr:215:5 in 'divide_rescued'
  from src/components/framework/src/ext/routing/annotation_route_loader.cr:8:5 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'execute'
  from src/components/framework/src/route_handler.cr:76:16 in 'handle_raw'
  from src/components/framework/src/route_handler.cr:19:5 in 'handle'
  from src/components/framework/src/athena.cr:161:27 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'process'
  from /usr/lib/crystal/http/server.cr:515:5 in 'handle_client'
  from /usr/lib/crystal/http/server.cr:468:13 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'run'
  from /usr/lib/crystal/fiber.cr:98:34 in '->'
  from ???

2022-01-08T20:45:14.132652Z   INFO - athena.routing: Matched route 'example_controller_divide_rescued' -- route: "example_controller_divide_rescued", route_parameters: {"_route" => "example_controller_divide_rescued", "_controller" => "ExampleController#divide_rescued", "num1" => "10", "num2" => "10"}, request_uri: "/divide_rescued/10/10", method: "GET"
```

#### Customization

By default the Athena Framework utilizes the default [Log::Formatter](https://crystal-lang.org/api/Log/Formatter.html) and [Log::Backend](https://crystal-lang.org/api/Log/Backend.html)s Crystal defines. This of course can be customized via interacting with Crystal's [Log](https://crystal-lang.org/api/Log.html) module. It is also possible to control what exceptions, and with what severity, will be logged by redefining the `log_exception` method within [ATH::Listeners::Error][].

### Middleware

Unlike other frameworks, Athena Framework leverages event based middleware instead of a pipeline based approach. This enables a lot of flexibility in that there is nothing extra that needs to be done to register the listener other than creating a service for it:

```crystal
@[ADI::Register]
class CustomListener
  include AED::EventListenerInterface

  @[AEDA::AsEventListener]
  def on_response(event : ATH::Events::Response) : Nil
    event.response.headers["FOO"] = "BAR"
  end
end
```

Similarly, the framework itself is implemented using the same features available to the users. Thus it is very easy to run specific listeners before/after the built-in ones if so desired.

TIP: Check out the `debug:event-dispatcher` [command](../architecture/console.md) for an easy way to see all the listeners and the order in which they are executed.

### Testing

Many Athena components include a `Spec` module that includes common/helpful testing utilities/types for testing that specific component. The framework itself defines some of its own testing types, mainly to allow for easily integration testing [ATH::Controller][]s via [ATH::Spec::APITestCase][] and also provides many helpful `HTTP` related [expectations][ATH::Spec::Expectations::HTTP].

```crystal
require "athena"
require "athena/spec"

class ExampleController < ATH::Controller
  @[ATHA::QueryParam("negative")]
  @[ARTA::Get("/add/{value1}/{value2}")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end
end

struct ExampleControllerTest < ATH::Spec::APITestCase
  def test_add_positive : Nil
    self.get("/add/5/3").body.should eq "8"
  end

  def test_add_negative : Nil
    self.get("/add/5/3?negative=true").body.should eq "-8"
  end
end

# Run all test case tests.
ASPEC.run_all
```

See the [Spec](../architecture/spec.md) component for more information.

### WebSockets

Currently due to Athena Framework's [architecture](../architecture/README.md#framework-architecture), WebSockets are not directly supported.
However the framework does allow prepending [HTTP::Handler](https://crystal-lang.org/api/HTTP/Handler.html) to the internal server.
This could be used to leverage the standard library's [HTTP::WebSocketHandler](https://crystal-lang.org/api/HTTP/WebSocketHandler.html) handler
or a third party library such as https://github.com/cable-cr/cable.

```crystal
require "athena"

# ...

ws_handler = HTTP::WebSocketHandler.new do |ws, ctx|
  ws.on_ping { ws.pong ctx.request.path }
end

ATH.run prepend_handlers: [ws_handler]
```

In the future, a goal is to have an integration with https://mercure.rocks/, which would allow for the majority of WebSocket use cases in a way that better fits into the Athena ecosystem.
