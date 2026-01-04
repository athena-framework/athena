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

An [AHTTP::Response](/HTTP/Response) can be used to fully customize the response; such as returning a specific status code, or adding some one-off headers.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  # A GET endpoint returning an `AHTTP::Response`.
  # Can be used to return raw data, such as HTML or CSS etc, in a one-off manner.
  @[ARTA::Get("/index")]
  def index : AHTTP::Response
    AHTTP::Response.new(
      "<h1>Welcome to my website!</h1>",
      headers: HTTP::Headers{"content-type" => MIME.from_extension(".html")}
    )
  end
end

ATH.run

# GET /index # => "<h1>Welcome to my website!</h1>"
```

A [View](./middleware.md#4-view-event) event is emitted if the returned value is _NOT_ an [AHTTP::Response](/HTTP/Response).
By default, non `AHTTP::Response`s are JSON serialized.
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
  def add(value1 : Int32, value2 : Int32) : Int32
    value1 + value2
  end
end

ATH.run

# GET /add/2/3    # => 5
# GET /add/foo/12 # => {"code":400,"message":"Required parameter 'value1' with value 'foo' could not be converted into a valid 'Int32'"}
```

TIP: For more complex conversions, consider creating a [Value Resolver](/Framework/Controller/ValueResolvers/Interface) to encapsulate the logic.

#### Query Parameters

[ATHA::MapQueryParameter](/Framework/Annotations/MapQueryParameter) can be used to map a query parameter directly to a controller action parameter.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Get("/")]
  def index(@[ATHA::MapQueryParameter] page : Int32) : Int32
    page
  end
end

ATH.run

# GET /          # => {"code":404,"message":"Missing query parameter: 'page'."}
# GET /?page=10  # => 10
# GET /?page=bar # => {"code":404,"message":"Invalid query parameter: 'page'."}
```

This works well enough for one-off parameters.
However [ATHA::MapQueryString](/Framework/Annotations/MapQueryString) can be used to the request's query string into a DTO type, much like how `JSON::Serializable` works for example.
In addition to making it easier to reuse, it also allows for enhanced validation of the query parameters via the [`Athena::Validator`](/Validator/#validating-objects) component.

### Raw Request

Restricting an action argument to [AHTTP::Request](/HTTP/Request) will provide the raw request object.
This can be useful to access data directly off the request object, such as consuming the request's body.
This approach is fine for simple or one-off endpoints.

TIP: Check out [ATHR::RequestBody](/Framework/Controller/ValueResolvers/RequestBody) for a better way to handle this.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Post("/data")]
  def data(request : AHTTP::Request) : String
    raise AHK::Exception::BadRequest.new "Request body is empty." unless body = request.body

    JSON.parse(body).as_h["name"].as_s
  end
end

ATH.run

# POST /data body: {"id":1,"name":"Jim"} # => Jim
```

### Streaming Response

By default `AHTTP::Response` content is written all at once to the response's `IO`.
However in some cases the content may be too large to fit into memory. In this case an [AHTTP::StreamedResponse](/HTTP/StreamedResponse) may be used to stream the content back to the client.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ARTA::Get(path: "/users")]
  def users : AHTTP::Response
    AHTTP::StreamedResponse.new headers: HTTP::Headers{"content-type" => "application/json; charset=UTF-8"} do |io|
      User.all.to_json io
    end
  end
end

ATH.run

# GET /athena/users" # => [{"id":1,...},...]
```

## File Uploads

Athena supports the [opt-in](/Framework/Bundle/Schema/FileUploads/) feature of populating [AHTTP::Request#files](/HTTP/Request/#Athena::HTTP::Request#files)
based on the files included in a `multipart/form-data` file upload request.
A [HTTP::FormData::Part](https://crystal-lang.org/api/HTTP/FormData/Part.html) without a *filename* is considered to be just a normal textual field and will be added to [AHTTP::Request#attributes](/HTTP/Request/#Athena::HTTP::Request#attributes).
These values can be provided to the controller action in the same way route parameters can.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Post(path: "/avatar")]
  def avatar(request : AHTTP::Request) : String
    request.files["profile_picture"][0].client_original_name
  end
end

ATH.configure({
  framework: {
    file_uploads: {
      enabled: true,
    },
  },
})

ATH.run

# POST /avatar" (multipart/form-data request with `profile_picture` key pointing to the `pic.png` file) # => pic.png
```

TIP: Check out [ATHA::MapUploadedFile](/Framework/Annotations/MapUploadedFile/) for a better way to handle this.

## File Response

An [AHTTP::BinaryFileResponse](/HTTP/BinaryFileResponse) may be used to return static files/content.
This response type handles caching, partial requests, and setting the relevant headers.
The Athena Framework also supports downloading of dynamically generated content by using an [AHTTP::Response](/HTTP/Response) with the [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header.
[AHTTP::HeaderUtils.make_disposition](/HTTP/HeaderUtils/#Athena::HTTP::HeaderUtils.make_disposition(disposition,filename,fallback_filename)) can be used to easily build the header.

```crystal
require "athena"
require "mime"

class ExampleController < ATH::Controller
  @[ARTA::Get(path: "/data/export")]
  def data_export : AHTTP::Response
    content = # ...

    AHTTP::Response.new(
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
This can be achieved by combining an [AHTTP::BinaryFileResponse](/HTTP/BinaryFileResponse) with the [request](./middleware.md#1-request-event) event;
checking if the request's path represents a file/directory within the application's public directory and returning the file if so.

```crystal
# Register a request event listener to handle returning static files.
@[ADI::Register]
struct StaticFileListener
  # This could be parameter if the directory changes between environments.
  private PUBLIC_DIR = Path.new("public").expand

  # Run this listener with a very high priority so it is invoked before any application logic.
  @[AEDA::AsEventListener(priority: 256)]
  def on_request(event : AHK::Events::Request) : Nil
    # Fallback if the request method isn't intended for files.
    # Alternatively, a 405 could be thrown if the server is dedicated to serving files.
    return unless event.request.method.in? "GET", "HEAD"

    original_path = event.request.path
    request_path = URI.decode original_path

    # File path cannot contains '\0' (NUL).
    if request_path.includes? '\0'
      raise AHK::Exception::BadRequest.new "File path cannot contain NUL bytes."
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
                       AHTTP::RedirectResponse.new redirect_path
                     elsif File.file? file_path
                       AHTTP::BinaryFileResponse.new file_path
                     else
                       # Nothing to do.
                       return
                     end
  end
end
```

## URL Generation

A common use case, especially when rendering `HTML`, is generating links to other routes based on a set of provided parameters.
When in the context of a request, the scheme and hostname of a [ART::Generator::ReferenceType::ABSOLUTE_URL](/Routing/Generator/ReferenceType/#Athena::Routing::Generator::ReferenceType::ABSOLUTE_URL) defaults to `http` and `localhost` respectively, if they could not be extracted from the request.

### In Controllers

The parent [ATH::Controller](/Framework/Controller) type provides some helper methods for generating URLs within the context of a controller.

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
  def redirect : AHTTP::RedirectResponse
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

NOTE: Passing arguments to `#generate_url` that are not part of the route definition are included within the query string of the generated URL.
```crystal
self.generate_url "blog", page: 2, category: "Crystal"
# The "blog" route only defines the "page" parameter; the generated URL is:
# /blog/2?category=Crystal
```

### In Services

A service can define a constructor parameter typed as [ART::Generator::Interface](/Routing/Generator/Interface) in order to obtain the `router` service:

```crystal
@[ADI::Register]
class SomeService
  def initialize(@url_generator : ART::Generator::Interface); end

  def some_method : Nil
    sign_up_page = @url_generator.generate "sign_up"

    # ...
  end
end
```

### In Commands

Generating URLs in [commands](./commands.md) works the same as in a service.
However, commands are not executed in an HTTP context.
Because of this, absolute URLs will always generate as `http://localhost/` instead of your actual host name.

The solution to this is to configure the [framework.router.default_uri](/Framework/Bundle/Schema/Router/#Athena::Framework::Bundle::Schema::Router#default_uri) configuration value.
This'll ensure URLs generated within commands have the proper host.

```crystal
ATH.configure({
  framework: {
    router: {
      default_uri: "https://example.com/my/path",
    },
  },
})
```

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

As mentioned earlier, controller action responses are JSON serialized if the controller action does _NOT_ return an [AHTTP::Response](/HTTP/Response).
The [Negotiation](/Negotiation) component enhances the view layer of the Athena Framework by enabling [content negotiation](https://tools.ietf.org/html/rfc7231#section-5.3) support; making it possible to write format agnostic controllers by placing a layer of abstraction between the controller and generation of the final response content.
Or in other words, allow having the same controller action be rendered based on the request's [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) header and the format priority configuration.

### Format Priority

The content negotiation logic is disabled by default, but can be easily enabled via the related [bundle configuration](./configuration.md).
Content negotiation configuration is represented by an array of [rules](/Framework/Bundle/Schema/FormatListener/#Athena::Framework::Bundle::Schema::FormatListener#rules) used to describe allowed formats, their priorities, and how things should function if a unsupported format is requested.

For example, say we configured things like:

```crystal
ATH.configure({
  framework: {
    format_listener: {
      enabled: true,
      rules:   [
        # Setting fallback_format to json means that instead of considering
        # the next rule in case of a priority mismatch, json will be used.
        {priorities: ["json", "xml"], host: /api\.example\.com/, fallback_format: "json"},

        # Setting fallback_format to false means that instead of considering
        # the next rule in case of a priority mismatch, a 406 will be returned.
        {path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false},

        # Setting fallback_format to nil (or not including it) means that
        # in case of a priority mismatch the next rule will be considered.
        {path: /^\/admin/, priorities: ["xml", "html"]},

        # Setting a priority to */* basically means any format will be matched.
        {priorities: ["text/html", "*/*"], fallback_format: "html"},
      ],
    },
  },
})
```

Assuming an `accept` header with the value `text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8,application/json`: a request made to `/foo` from the `api.example.com` hostname; the request format would be `json`. If the request was not made from that hostname; the request format would be `html`. The rules can be as complex or as simple as needed depending on the use case of your application.

### View Handler

The [ATH::View::ViewHandler](/Framework/View/ViewHandler) is responsible for generating an [AHTTP::Response](/HTTP/Response) in the format determined by the [ATH::Listeners::Format](/Framework/Listeners/Format), otherwise falling back on the request's [format](/HTTP/Request/#Athena::HTTP::Request#format(mime_type)), defaulting to `json`.
The view handler has a options that may also be [configured](./configuration.md) via the [ATH::Bundle::Schema::ViewHandler](/Framework/Bundle/Schema/ViewHandler) schema.

```crystal
ATH.configure({
  framework: {
    view_handler: {
      # The HTTP::Status to use if there is no response body, defaults to 204.
      empty_content_status: :im_a_teapot,

      # If `nil` values should be serialized, defaults to false.
      serialize_nil: true
    },
  },
})
```

## Views

An [ATH::View](/Framework/View) is intended to act as an in between returning raw data and an [AHTTP::Response](/HTTP/Response).
In other words, it still invokes the [view](./middleware.md#4-view-event) event, but allows customizing the response's status and headers.
Convenience methods are defined in the base controller type to make creating views easier. E.g. [ATH::Controller#view](/Framework/Controller/#Athena::Framework::Controller#view(data,status,headers)).

### View Format Handlers

By default the Athena Framework uses `json` as the default response format.
However it is possible to extend the [ATH::View::ViewHandler](/Framework/View/ViewHandler) to support additional, and even custom, formats.
This is achieved by creating an [ATH::View::FormatHandlerInterface](/Framework/View/FormatHandlerInterface) instance that defines the logic needed to turn an [ATH::View](/Framework/View) into an [AHTTP::Response](/HTTP/Response).

The implementation can be as simple/complex as needed for the given format.
Official handlers could be provided in the future for common formats such as `html`, probably via an integration with some form of tempting engine utilizing [custom annotations](./configuration.md#custom-annotations) to specify the format.

### Adding/Customizing Formats

[AHTTP::Request::FORMATS](/HTTP/Request/#Athena::HTTP::Request::FORMATS) represents the formats supported by default.
However this list is not exhaustive and may need altered application to application; such as [registering](/HTTP/Request/#Athena::HTTP::Request.register_format(format,mime_types)) new formats.

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
  def call(view_handler : ATH::View::ViewHandlerInterface, view : ATH::ViewBase, request : AHTTP::Request, format : String) : AHTTP::Response
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

    # Return an AHTTP::Response with the rendered CSV content.
    # Athena handles setting the proper content-type header based on the format.
    # But could be overridden here if so desired.
    AHTTP::Response.new content
  end

  # :inherit:
  def format : String
    "csv"
  end
end

ATH.configure({
  framework: {
    format_listener: {
      enabled: true,
      rules:   [
        # Allow json and csv formats, falling back on json if an unsupported format is requested.
        {priorities: ["json", "csv"], fallback_format: "json"}
      ]
    },
  }
})

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
