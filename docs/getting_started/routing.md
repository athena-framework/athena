## Controllers

The Athena Framework is a MVC based framework, as such, the logic to handle a given route is defined within an [ATH::Controller](/Framework/Controller).
Athena Framework takes an annotation based approach to routing.
An annotation, such as `ARTA::Get` is applied to an instance method of a controller class, which will be executed when that endpoint receives a request.

### Creating a Route

In Athena Framework, controllers are simply classes and route actions are simply methods.
This means they can be documented/tested as you would any Crystal class/method.
However see the [testing](./testing.md#testing-controllers) section for how to best test a controller.

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

Routing is handled via the [Athena::Routing](/Routing) component.
It provides a flexible and robust foundation for handling determining which route should match a given request.

TIP: Check out the `debug:router` [command](./commands.md) to view all of the routes the framework is aware of within your application.

### Raw Response

An [ATH::Response](/Framework/Response) can be used to fully customize the response; such as returning a specific status code, or adding some one-off headers.

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

A [View](./middleware.md#4-view-event) event is emitted if the returned value is _NOT_ an [ATH::Response](/Framework/Response).
By default, non `ATH::Response`s are JSON serialized.
However, this event can be listened on to customize how the value is serialized.
More on this in the [Content Negotiation](#content-negotiation) section.

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

TIP: For more complex conversions, consider creating a [Value Resolver](/Framework/Controller/ValueResolvers/Interface) to encapsulate the logic.

#### Query Params

[ATHA::QueryParam](/Framework/Annotations/QueryParam) and [ATHA::RequestParam](/Framework/Annotations/RequestParam)s are defined via annotations and map directly to the method's arguments.

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

### Raw Request

Restricting an action argument to [ATH::Request](/Framework/Request) will provide the raw request object.
This can be useful to access data directly off the request object, such as consuming the request's body.
This approach is fine for simple or one-off endpoints.

TIP: Check out [ATHR::RequestBody](/Framework/Controller/ValueResolvers/RequestBody) for a better way to handle this.

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


### Streaming Response

By default `ATH::Response` content is written all at once to the response's `IO`.
However in some cases the content may be too large to fit into memory. In this case an [ATH::StreamedResponse](/Framework/StreamedResponse) may be used to stream the content back to the client.

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

## File Response

An [ATH::BinaryFileResponse](/Framework/BinaryFileResponse) may be used to return static files/content.
This response type handles caching, partial requests, and setting the relevant headers.
The Athena Framework also supports downloading of dynamically generated content by using an [ATH::Response](/Framework/Response) with the [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header.
[ATH::HeaderUtils.make_disposition](/Framework/HeaderUtils/#Athena::Framework::HeaderUtils.make_disposition(disposition,filename,fallback_filename)) can be used to easily build the header.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ARTA::Get(path: "/data/export")]
  def data_export : ATH::Response
    content = # ...

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

### Static Files

Static files can also be served from an Athena application.
This can be achieved by combining an [ATH::BinaryFileResponse](/Framework/BinaryFileResponse) with the [request](./middleware.md#1-request-event) event;
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

## URL Generation

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

When a route is generated in the context of a request, the scheme and hostname of a [ART::Generator::ReferenceType::ABSOLUTE_URL](/Routing/Generator/ReferenceType/#Athena::Routing::Generator::ReferenceType::ABSOLUTE_URL) defaults to `http` and `localhost` respectively, if they could not be extracted from the request.
However, in cases where there is no request to use, such as within an [ACON::Command](/Console/Command), `http://localhost/` would always be the scheme and hostname of the generated URL.
[ATH::Parameters.configure](/Framework/Parameters/#Athena::Framework::Parameters.configure) can be used to customize this, as well as define a global path prefix when generating the URLs.

## WebSockets

Currently due to Athena Framework's [architecture](./middleware.md#events), WebSockets are not directly supported.
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

Alternatively, the [Athena::Mercure](/Mercure) component may be used as a replacement of the more common websocket use cases.

## Content Negotiation

As mentioned earlier, controller action responses are JSON serialized if the controller action does _NOT_ return an [ATH::Response](/Framework/Response).
The [Negotiation](/Negotiation) component enhances the view layer of the Athena Framework by enabling [content negotiation](https://tools.ietf.org/html/rfc7231#section-5.3) support; making it possible to write format agnostic controllers by placing a layer of abstraction between the controller and generation of the final response content.
Or in other words allow having the same controller action be rendered based on the request's [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) `HTTP` header and the format priority configuration.

### Format Priority

The content negotiation logic is disabled by default, but can be easily enabled by redefining [ATH::Config::ContentNegotiation.configure](/Framework/Config/ContentNegotiation/#Athena::Framework::Config::ContentNegotiation.configure) with the desired configuration.
Content negotiation configuration is represented by an array of [Rule](/Framework/Config/ContentNegotiation/Rule/) used to describe allowed formats, their priorities, and how things should function if a unsupported format is requested.

For example, say we configured things like:

```crystal
def ATH::Config::ContentNegotiation.configure
  new(
    # Setting fallback_format to json means that instead of considering
    # the next rule in case of a priority mismatch, json will be used.
    Rule.new(priorities: ["json", "xml"], host: "api.example.com", fallback_format: "json"),
    # Setting fallback_format to false means that instead of considering
    # the next rule in case of a priority mismatch, a 406 will be returned.
    Rule.new(path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false),
    # Setting fallback_format to nil (or not including it) means that
    # in case of a priority mismatch the next rule will be considered.
    Rule.new(path: /^\/admin/, priorities: ["xml", "html"]),
    # Setting a priority to */* basically means any format will be matched.
    Rule.new(priorities: ["text/html", "*/*"], fallback_format: "html"),
  )
end
```

Assuming an `accept` header with the value `text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8,application/json`: a request made to `/foo` from the `api.example.com` hostname; the request format would be `json`. If the request was not made from that hostname; the request format would be `html`. The rules can be as complex or as simple as needed depending on the use case of your application.

### View Handler

The [ATH::View::ViewHandler](/Framework/View/ViewHandler) is responsible for generating an [ATH::Response](/Framework/Response) in the format determined by the [ATH::Listeners::Format](/Framework/Listeners/Format), otherwise falling back on the request's [format](/Framework/Request/#Athena::Framework::Request#format(mime_type)), defaulting to `json`.
The view handler has a few configurable options that can be customized if so desired.
This can be achieved via redefining [Athena::Framework::Config::ViewHandler.configure](/Framework/Config/ViewHandler/#Athena::Framework::Config::ViewHandler.configure).

```crystal
def ATH::Config::ViewHandler.configure : ATH::Config::ViewHandler
  new(
    # The HTTP::Status to use if there is no response body, defaults to 204.
    empty_content_status: :im_a_teapot,
    # If `nil` values should be serialized, defaults to false.
    emit_nil: true
  )
end
```

## Views

An [ATH::View](/Framework/View) is intended to act as an in between returning raw data and an [ATH::Response](/Framework/Response).
In other words, it still invokes the [view](./middleware.md#4-view-event) event, but allows customizing the response's status and headers.
Convenience methods are defined in the base controller type to make creating views easier. E.g. [ATH::Controller#view](/Framework/Controller/#Athena::Framework::Controller#view(data,status,headers)).

### View Format Handlers

By default the Athena Framework uses `json` as the default response format.
However it is possible to extend the [ATH::View::ViewHandler](/Framework/View/ViewHandler) to support additional, and even custom, formats.
This is achieved by creating an [ATH::View::FormatHandlerInterface](/Framework/View/FormatHandlerInterface) instance that defines the logic needed to turn an [ATH::View](/Framework/View) into an [ATH::Response](/Framework/Response).

The implementation can be as simple/complex as needed for the given format.
Official handlers could be provided in the future for common formats such as `html`, probably via an integration with some form of tempting engine utilizing [custom annotations](./configuration.md#custom-annotations) to specify the format.

### Adding/Customizing Formats

[ATH::Request::FORMATS](/Framework/Request/#Athena::Framework::Request::FORMATS) represents the formats supported by default.
However this list is not exhaustive and may need altered application to application; such as [registering](/Framework/Request/#Athena::Framework::Request.register_format(format,mime_types)) new formats.

#### Example

The following is a demonstration of how the various negotiation features can be used in conjunction. The example includes:

1. Defining a custom [ATH::View::ViewHandler](/Framework/View/ViewHandler) for the `csv` format.
1. Enabling content negotiation, supporting `json` and `csv` formats, falling back to `json`.
1. An endpoint returning an [ATH::View](/Framework/View) that sets a custom HTTP status.

```crystal
require "athena"
require "csv"

# An interface to denote a type can provide its data in CSV format.
#
# An easier/more robust implementation can probably be thought of,
# however this is mainly for demonstration purposes.
module CSVRenderable
  abstract def to_csv(builder : CSV::Builder) : Nil
end

# Define an example entity type.
record User, id : Int64, name : String, email : String do
  include CSVRenderable
  include JSON::Serializable

  # Define the headers this type has.
  def self.headers : Enumerable(String)
    {
      "id",
      "name",
      "email",
    }
  end

  def to_csv(builder : CSV::Builder) : Nil
    # Add the related values based on `self.`
    builder.row @id, @name, @email
  end
end

# Register our handler as a service.
@[ADI::Register]
class CSVFormatHandler
  # Implement the interface.
  include ATH::View::FormatHandlerInterface

  # :inherit:
  def call(view_handler : ATH::View::ViewHandlerInterface, view : ATH::ViewBase, request : ATH::Request, format : String) : ATH::Response
    view_data = view.data

    headers = if view_data.is_a? Enumerable
                typeof(view_data.first).headers
              else
                view_data.class.headers
              end

    data = if view_data.is_a? Enumerable
             view_data
           else
             {view_data}
           end

    # Assume each item has the same headers.
    content = CSV.build do |csv|
      csv.row headers

      data.each do |r|
        r.to_csv csv
      end
    end

    # Return an ATH::Response with the rendered CSV content.
    # Athena handles setting the proper content-type header based on the format.
    # But could be overridden here if so desired.
    ATH::Response.new content
  end

  # :inherit:
  def format : String
    "csv"
  end
end

# Configure the format listener.
def ATH::Config::ContentNegotiation.configure
  new(
    # Allow json and csv formats, falling back on json if an unsupported format is requested.
    Rule.new(priorities: ["json", "csv"], fallback_format: "json"),
  )
end

class ExampleController < ATH::Controller
  @[ARTA::Get("/users")]
  def get_users : ATH::View(Array(User))
    self.view([
      User.new(1, "Jim", "jim@example.com"),
      User.new(2, "Bob", "bob@example.com"),
      User.new(3, "Sally", "sally@example.com"),
    ], status: :im_a_teapot)
  end
end

ATH.run
```
