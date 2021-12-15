Athena does not have any other dependencies outside of [Crystal](https://crystal-lang.org) and [Shards](https://crystal-lang.org/reference/the_shards_command/index.html).
It is designed in such a way to be non-intrusive, and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  athena:
    github: athena-framework/athena
    version: ~> 0.15.0
```

Run `shards install`. This will install Athena and its required dependencies.

## Usage

Athena has a goal of being easy to start using for simple use cases, while still allowing flexibility/customizability for larger more complex use cases.

### Routing

Athena is a MVC based framework, as such, the logic to handle a given route is defined in an [ATH::Controller][Athena::Framework::Controller] class.

```crystal
require "athena"

# Define a controller
class ExampleController < ATH::Controller
  # Define an action to handle the related route
  @[ATHA::Get("/")]
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

Annotations applied to the methods are used to define the HTTP method this method handles, such as [ATHA::Get][Athena::Framework::Annotations::Get] or [ATHA::Post][Athena::Framework::Annotations::Post]. A macro DSL also exists to make them a bit less verbose;
[ATH::Controller.get][Athena::Framework::Controller:get(path,*args,**named_args,&)] or [ATH::Controller.post][Athena::Framework::Controller:post(path,*args,**named_args,&)]. The [ATHA::Route][Athena::Framework::Annotations::Route] annotation can also be used to define custom `HTTP` methods.

Controllers are simply classes and routes are simply methods. Controllers and actions can be documented/tested as you would any Crystal class/method.

### Route Parameters

Arguments are converted to their expected types if possible, otherwise an error response is automatically returned.
The values are provided directly as method arguments, thus preventing the need for `env.params.url["name"]` and any boilerplate related to it. Just like normal method arguments, default values can be defined. The method's return type adds some type safety to ensure the expected value is being returned.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ATHA::Get("/add/:value1/:value2")]
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

[ATHA::QueryParam][Athena::Framework::Annotations::QueryParam] and [ATHA::RequestParam][Athena::Framework::Annotations::RequestParam]s are defined via annotations and map directly to the method's arguments. See the related annotation docs for more information.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ATHA::Get("/")]
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

Restricting an action argument to [ATH::Request][] will provide the raw request object. This can be useful to access data directly off the request object, such consuming the request's body. This approach is fine for simple or one-off endpoints, however for more complex/common request data processing, it is suggested to create a [Param Converter](advanced_usage.md#param-converters) to handle deserializing directly into an object.

TIP: Checkout [Athena::Framework::RequestBodyConverter][Athena::Framework::RequestBodyConverter] for a better way to handle this.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ATHA::Post("/data")]
  def data(request : ATH::Request) : String
    raise ATH::Exceptions::BadRequest.new "Request body is empty." unless body = request.body
    
    JSON.parse(body).as_h["name"].as_s
  end
end

ATH.run

# POST /data body: {"id":1,"name":"Jim"} # => Jim
```

#### Returning Raw Data

An [ATH::Response][Athena::Framework::Response] can be used to fully customize the response; such as returning a specific status code, or adding some one-off headers.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  # A GET endpoint returning an `ATH::Response`.
  # Can be used to return raw data, such as HTML or CSS etc, in a one-off manner.
  @[ATHA::Get("/index")]
  def index : ATH::Response
    ATH::Response.new "<h1>Welcome to my website!</h1>", headers: HTTP::Headers{"content-type" => MIME.from_extension(".html")}
  end
end

ATH.run

# GET /index # => "<h1>Welcome to my website!</h1>"
```

An [ATH::Events::View][Athena::Framework::Events::View] is emitted if the returned value is _NOT_ an [ATH::Response][Athena::Framework::Response]. By default, non [ATH::Response][Athena::Framework::Response]s are JSON serialized.
However, this event can be listened on to customize how the value is serialized.

##### Streaming Response

By default `ATH::Response` content is written all at once to the response's `IO`. However in some cases the content may be too large to fit into memory. In this case an [ATH::StreamedResponse][Athena::Framework::StreamedResponse] may be used to stream the content back to the client.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ATHA::Get(path: "/users")]
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

An [ATH::BinaryFileResponse][Athena::Framework::BinaryFileResponse] may be used to return [static files](../cookbook/listeners.md#static-files). This response type handles caching, partial requests, and setting the relevant headers. Athena also supports downloading of dynamically generated content by using an [ATH::Response][Athena::Framework::Response] with the [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header. [ATH::HeaderUtils.make_dispostion][Athena::Framework::HeaderUtils.make_disposition(disposition,filename,fallback_filename)] can be used to easily build the header.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ATHA::Get(path: "/data/export")]
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

### URL Generation

A common use case, especially when rendering `HTML`, is generating links to other routes based on a set of provided parameters.

```crystal
require "athena"

class ExampleController < ATH::Controller
  # Define a route to redirect to, explicitly naming this route `add`.
  # The default route name is controller + method down snake-cased; e.x. `example_controller_add`.
  @[ATHA::Get("/add/:value1/:value2", name: "add")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end

  # Define a route that redirects to the `add` route with fixed parameters.
  @[ATHA::Get("/")]
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

See [ART::URLGeneratorInterface][Athena::Routing::URLGeneratorInterface] in the API Docs for more details.

### Error Handling

Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, [ATH::Exceptions::HTTPException][Athena::Framework::Exceptions::HTTPException].
Custom `HTTP` errors can also be defined by inheriting from [ATH::Exceptions::HTTPException][Athena::Framework::Exceptions::HTTPException] or a child type.
A use case for this could be allowing additional data/context to be included within the exception.

Non [ATH::Exceptions::HTTPException][Athena::Framework::Exceptions::HTTPException] exceptions are represented as a `500 Internal Server Error`.

When an exception is raised, Athena emits the [ATH::Events::Exception][Athena::Framework::Events::Exception] event to allow an opportunity for it to be handled.
By default these exceptions will return a `JSON` serialized version of the exception, via [ATH::ErrorRenderer][Athena::Framework::ErrorRenderer], that includes the message and code; with the proper response status set.
If the exception goes unhandled, i.e. no listener sets an [ATH::Response][Athena::Framework::Response]. By default, non [ATH::Response][Athena::Framework::Response] on the event, then the request is finished and the exception is re-raised.

```crystal
require "athena"

class ExampleController < ATH::Controller
  get "divide/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
    num1 // num2
  end

  get "divide_rescued/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
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

Logging is handled via Crystal's [Log](https://crystal-lang.org/api/Log.html) module. Athena logs when a request matches a controller action, as well as any exception. This of course can be augmented with additional application specific messages.

```bash
2020-12-06T17:20:12.334700Z   INFO - Server has started and is listening at http://0.0.0.0:3000
2020-12-06T17:20:17.163953Z   INFO - athena.routing: Matched route /divide/10/0 -- uri: "/divide/10/0", method: "GET", path_params: {"num2" => "0", "num1" => "10"}, query_params: {}
2020-12-06T17:20:17.280199Z  ERROR - athena.routing: Uncaught exception #<DivisionByZeroError:Division by 0> at ../../../../../../usr/lib/crystal/int.cr:138:7 in 'check_div_argument'
Division by 0 (DivisionByZeroError)
  from ../../../../../../usr/lib/crystal/int.cr:138:7 in 'check_div_argument'
  from ../../../../../../usr/lib/crystal/int.cr:102:5 in '//'
  from src/athena.cr:151:5 in 'get_divide__num1__num2'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'execute'
  from src/route_handler.cr:80:5 in 'handle_raw'
  from src/route_handler.cr:14:21 in 'handle'
  from src/athena.cr:127:9 in '->'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'process'
  from ../../../../../../usr/lib/crystal/http/server.cr:513:5 in 'handle_client'
  from ../../../../../../usr/lib/crystal/http/server.cr:468:13 in '->'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'run'
  from ../../../../../../usr/lib/crystal/fiber.cr:92:34 in '->'
  from ???

2020-12-06T17:20:18.979050Z   INFO - athena.routing: Matched route /divide_rescued/10/0 -- uri: "/divide_rescued/10/0", method: "GET", path_params: {"num2" => "0", "num1" => "10"}, query_params: {}
2020-12-06T17:20:18.980397Z   WARN - athena.routing: Uncaught exception #<Athena::Framework::Exceptions::BadRequest:Invalid num2:  Cannot divide by zero> at src/athena.cr:159:5 in 'get_divide_rescued__num1__num2'
Invalid num2:  Cannot divide by zero (Athena::Framework::Exceptions::BadRequest)
  from src/athena.cr:159:5 in 'get_divide_rescued__num1__num2'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'execute'
  from src/route_handler.cr:80:5 in 'handle_raw'
  from src/route_handler.cr:14:21 in 'handle'
  from src/athena.cr:127:9 in '->'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'process'
  from ../../../../../../usr/lib/crystal/http/server.cr:513:5 in 'handle_client'
  from ../../../../../../usr/lib/crystal/http/server.cr:468:13 in '->'
  from ../../../../../../usr/lib/crystal/primitives.cr:255:3 in 'run'
  from ../../../../../../usr/lib/crystal/fiber.cr:92:34 in '->'
  from ???

2020-12-06T17:20:21.993811Z   INFO - athena.routing: Matched route /divide_rescued/10/10 -- uri: "/divide_rescued/10/10", method: "GET", path_params: {"num2" => "10", "num1" => "10"}, query_params: {}
```

#### Customization

By default Athena utilizes the default [Log::Formatter](https://crystal-lang.org/api/Log/Formatter.html) and [Log::Backend](https://crystal-lang.org/api/Log/Backend.html)s Crystal defines. This of course can be customized via interacting with Crystal's [Log](https://crystal-lang.org/api/Log.html) module. It is also possible to control what exceptions, and with what severity, exceptions will be logged by redefining the `log_exception` method within [ATH::Listeners::Error][Athena::Framework::Listeners::Error].
