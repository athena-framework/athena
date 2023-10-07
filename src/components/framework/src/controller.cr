# The core of any framework is routing; how a route is tied to an action.
# Athena takes an annotation based approach; an annotation, such as `ARTA::Get` is applied to an instance method of a controller class, which will be executed when that endpoint receives a request.
#
# Additional annotation also exist for defining a query parameter. See `ATHA::QueryParam` for more information.
#
# Child controllers must inherit from `ATH::Controller` (or an abstract child of it). Each request gets its own instance of the controller to better allow for DI via `Athena::DependencyInjection`.
#
# A route action can either return an `ATH::Response`, or some other type. If an `ATH::Response` is returned, then it is used directly. Otherwise an `ATH::Events::View` is emitted to convert
# the action result into an `ATH::Response`. By default, `ATH::Listeners::View` will JSON encode the value if it is not handled earlier by another listener.
#
# ### Example
# The following controller shows examples of the various routing features of Athena. `ATH::Controller` also defines various macro DSLs, such as `ATH::Controller.get` to make defining routes
# seem more Sinatra/Kemal like. See the documentation on the macros for more details.
#
# ```
# require "athena"
# require "mime"
#
# # The `ARTA::Route` annotation can also be applied to a controller class.
# # This can be useful for applying a common path prefix, defaults, requirements,
# # etc. to all actions in the controller.
# @[ARTA::Route(path: "/athena")]
# class TestController < ATH::Controller
#   # A GET endpoint returning an `ATH::Response`.
#   # Can be used to return raw data, such as HTML or CSS etc, in a one-off manor.
#   @[ARTA::Get(path: "/index")]
#   def index : ATH::Response
#     ATH::Response.new "<h1>Welcome to my website!</h1>", headers: HTTP::Headers{"content-type" => MIME.from_extension(".html")}
#   end
#
#   # A GET endpoint returning an `ATH::StreamedResponse`.
#   # Can be used to stream the response content to the client;
#   # useful if the content is too large to fit into memory.
#   @[ARTA::Get(path: "/users")]
#   def users : ATH::Response
#     ATH::StreamedResponse.new headers: HTTP::Headers{"content-type" => "application/json; charset=UTF-8"} do |io|
#       User.all.to_json io
#     end
#   end
#
#   # A GET endpoint with no params returning a `String`.
#   #
#   # Action return type restrictions are required.
#   @[ARTA::Get("/me")]
#   def get_me : String
#     "Jim"
#   end
#
#   # A GET endpoint with no params returning `Nil`.
#   # `Nil` return types are returned with a status
#   # of 204 no content
#   @[ARTA::Get("/no_content")]
#   def get_no_content : Nil
#     # Do stuff
#   end
#
#   # A GET endpoint with two `Int32` params returning an `Int32`.
#   #
#   # The parameters of a route _MUST_ match the parameters of the action.
#   # Type restrictions on action parameters are required.
#   @[ARTA::Get("/add/{val1}/{val2}")]
#   def add(val1 : Int32, val2 : Int32) : Int32
#     val1 + val2
#   end
#
#   # A GET endpoint with a required trailing slash, a `String` route param,
#   # and a required string query param that must match the given pattern; returning a `String`.
#   #
#   # Athena treats non `GET`/`HEAD` routes with a trailing slash as unique
#   # E.g. `POST /foo/bar/` versus `POST /foo/bar`.
#   # Be sure to keep you routes consistent!
#   #
#   # A non-nilable type denotes it as required. If the parameter is not supplied,
#   # and no default value is assigned, an `ATH::Exceptions::BadRequest` exception is raised.
#   @[ARTA::Get("/event/{event_name}/")]
#   @[ATHA::QueryParam("time", requirements: /\d:\d:\d/)]
#   def event_time(event_name : String, time : String) : String
#     "#{event_name} occurred at #{time}"
#   end
#
#   # A GET endpoint with an optional query parameter and optional path param
#   # with a default value; returning a `NamedTuple(user_id : Int32?, page : Int32)`.
#   #
#   # A nilable type denotes it as optional.
#   # If the parameter is not supplied (or could not be converted),
#   # and no default value is assigned, it is `nil`.
#   @[ATHA::QueryParam("user_id")]
#   @[ARTA::Get("/events/{page}")]
#   def events(user_id : Int32?, page : Int32 = 1) : NamedTuple(user_id: Int32?, page: Int32)
#     {user_id: user_id, page: page}
#   end
#
#   # A GET endpoint with route parameter requirements.
#   # The parameter must match the supplied Regex or this route will not be matched.
#   #
#   # This feature can allow multiple routes to exist with parameters in the same location,
#   # but with different requirements.
#   @[ARTA::Get("/time/{time}/", requirements: {"time" => /\d{2}:\d{2}:\d{2}/})]
#   def get_constraint(time : String) : String
#     time
#   end
#
#   # A POST endpoint with a route param and accessing the request body; returning a `Bool`.
#   #
#   # It is recommended to use param converters to pass an actual object representing the data (assuming the body is JSON)
#   # to the route's action; however the raw request body can be accessed by typing an action argument as `ATH::Request`.
#   @[ARTA::Post("/test/{expected}")]
#   def post_body(expected : String, request : ATH::Request) : Bool
#     expected == request.body.try &.gets_to_end
#   end
#
#   # An endpoint may also have more than one route annotation applied to it.
#   # This can be useful in allowing for a route to support multiple aliases.
#   @[ARTA::Get("/users/{id}")]
#   @[ARTA::Get("/people/{id}")]
#   def get_user(id : Int64) : User
#     # Fetch the user
#     user = ...
#
#     user
#   end
# end
#
# ATH.run
#
# # GET /athena/index                    # => <h1>Welcome to my website!</h1>
# # GET /athena/users                    # => [{"id":1,...},...]
# # GET /athena/wakeup/17                # => Morning, Allison it is currently 2020-02-01 18:38:12 UTC.
# # GET /athena/me                       # => "Jim"
# # GET /athena/add/50/25                # => 75
# # GET /athena/event/foobar?time=1:1:1  # => "foobar occurred at 1:1:1"
# # GET /athena/event/foobar/?time=1:1:1 # => "foobar occurred at 1:1:1"
# # GET /athena/events                   # => {"user_id":null,"page":1}
# # GET /athena/events/17?user_id=19     # => {"user_id":19,"page":17}
# # GET /athena/time/12:45:30            # => "12:45:30"
# # GET /athena/time/12:aa:30            # => 404 not found
# # GET /athena/no_content               # => 204 no content
# # GET /athena/users/19                 # => {"user_id":19}
# # GET /athena/people/19                # => {"user_id":19}
# # POST /athena/test/foo, body: "foo"   # => true
# ```
abstract class Athena::Framework::Controller
  macro inherited
    private CONTROLLER_ACTION_METHODS = [] of {String, String}

    macro method_added(m)
      \{%
         if (m.annotation(ARTA::Get) || m.annotation(ARTA::Post) || m.annotation(ARTA::Put) || m.annotation(ARTA::Delete) || m.annotation(ARTA::Patch) || m.annotation(ARTA::Link) || m.annotation(ARTA::Unlink) || m.annotation(ARTA::Head) || m.annotation(ARTA::Route))
           if CONTROLLER_ACTION_METHODS.includes?({@type.name.id, m.name.id})
             m.raise "A controller action named '##{m.name}' already exists within '#{@type.name}'."
           end

           CONTROLLER_ACTION_METHODS << {@type.name.id, m.name.id}
         end
      %}
    end
  end

  # Generates a URL to the provided *route* with the provided *params*.
  #
  # See `ART::Generator::Interface#generate`.
  def generate_url(route : String, params : Hash(String, _) = Hash(String, String?).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    # TODO: Make this type leverage a service locator for these common types.
    ADI.container.router.generate route, params.transform_values(&.to_s.as(String?)), reference_type
  end

  # Generates a URL to the provided *route* with the provided *params*.
  #
  # See `ART::Generator::Interface#generate`.
  def generate_url(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params)
    self.generate_url route, params.to_h.transform_keys(&.to_s), reference_type
  end

  # Returns an `ATH::RedirectResponse` to the provided *route* with the provided *params*.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   # Define a route to redirect to, explicitly naming this route `add`.
  #   # The default route name is controller + method down snake-cased; e.x. `example_controller_add`.
  #   @[ARTA::Get("/add/{value1}/{value2}", name: "add")]
  #   def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
  #     sum = value1 + value2
  #     negative ? -sum : sum
  #   end
  #
  #   # Define a route that redirects to the `add` route with fixed parameters.
  #   @[ARTA::Get("/")]
  #   def redirect : ATH::RedirectResponse
  #     self.redirect_to_route "add", {"value1" => 8, "value2" => 2}
  #   end
  # end
  #
  # ATH.run
  #
  # # GET / # => 10
  # ```
  def redirect_to_route(route : String, params : Hash(String, _) = Hash(String, String?).new, status : HTTP::Status = :found) : ATH::RedirectResponse
    self.redirect self.generate_url(route, params), status
  end

  # Returns an `ATH::RedirectResponse` to the provided *route* with the provided *params*.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   # Define a route to redirect to, explicitly naming this route `add`.
  #   # The default route name is controller + method down snake-cased; e.x. `example_controller_add`.
  #   @[ARTA::Get("/add/{value1}/{value2}", name: "add")]
  #   def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
  #     sum = value1 + value2
  #     negative ? -sum : sum
  #   end
  #
  #   # Define a route that redirects to the `add` route with fixed parameters.
  #   @[ARTA::Get("/")]
  #   def redirect : ATH::RedirectResponse
  #     self.redirect_to_route "add", value1: 8, value2: 2
  #   end
  # end
  #
  # ATH.run
  #
  # # GET / # => 10
  # ```
  def redirect_to_route(route : String, status : HTTP::Status = :found, **params) : ATH::RedirectResponse
    self.redirect_to_route route, params.to_h.transform_keys(&.to_s.as(String)), status
  end

  # Returns an `ATH::RedirectResponse` to the provided *url*, optionally with the provided *status*.
  #
  # ```
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("redirect/google")]
  #   def redirect_to_google : ATH::RedirectResponse
  #     self.redirect "https://google.com"
  #   end
  # end
  # ```
  def redirect(url : String | Path, status : HTTP::Status = HTTP::Status::FOUND) : ATH::RedirectResponse
    ATH::RedirectResponse.new url, status
  end

  # Returns an `ATH::View` that'll redirect to the provided *url*, optionally with the provided *status* and *headers*.
  #
  # Is essentially the same as `#redirect`, but invokes the [view](../../architecture/README.md#4-view-event) layer.
  def redirect_view(url : Status, status : HTTP::Status = HTTP::Status::FOUND, headers : HTTP::Headers = HTTP::Headers.new) : ATH::View
    ATH::View.create_redirect url, status, headers
  end

  # Returns an `ATH::View` that'll redirect to the provided *route*, optionally with the provided *params*, *status*, and *headers*.
  #
  # Is essentially the same as `#redirect_to_route`, but invokes the [view](../../architecture/README.md#4-view-event) layer.
  def route_redirect_view(route : Status, params : Hash(String, _) = Hash(String, String?).new, status : HTTP::Status = HTTP::Status::CREATED, headers : HTTP::Headers = HTTP::Headers.new) : ATH::View
    ATH::View.create_route_redirect route, params
  end

  # Returns an `ATH::View` with the provided *data*, and optionally *status* and *headers*.
  #
  # ```
  # @[ARTA::Get("/{name}")]
  # def say_hello(name : String) : ATH::View(NamedTuple(greeting: String))
  #   self.view({greeting: "Hello #{name}"}, :im_a_teapot)
  # end
  # ```
  def view(data = nil, status : HTTP::Status? = nil, headers : HTTP::Headers = HTTP::Headers.new) : ATH::View
    ATH::View.new data, status, headers
  end

  {% begin %}
    {% for method in ["DELETE", "GET", "HEAD", "PATCH", "POST", "PUT", "LINK", "UNLINK"] %}
      # Helper DSL macro for creating `{{method.id}}` actions.
      #
      # The first argument is the path that the action should handle; which maps to path on the HTTP method annotation.
      # The second argument is a variable amount of arguments with a syntax similar to Crystal's `record`.
      # There are also a few optional named arguments that map to the corresponding field on the HTTP method annotation.
      #
      # The macro simply defines a method based on the options passed to it. Additional annotations, such as for query params
      # or a param converter can simply be added on top of the macro.
      #
      # ### Optional Named Arguments
      # - `return_type` - The return type to set for the action. Defaults to `String` if not provided.
      # - `constraints` - Any constraints that should be applied to the route.
      #
      # ### Example
      #
      # ```
      # class ExampleController < ATH::Controller
      #   {{method.downcase.id}} "values/{value1<\\d+>}/{value2<\\d+\\.\\d+>}", value1 : Int32, value2 : Float64 do
      #     "Value1: #{value1} - Value2: #{value2}"
      #   end
      # end
      # ```
      macro {{method.downcase.id}}(path, *args, **named_args, &)
        @[ARTA::{{method.capitalize.id}}(path: \{{path}})]
        def {{method.downcase.id}}_\{{path.gsub(/\W/, "_").id}}(\{{*args}}) : \{{named_args[:return_type] || String}}
          \{{yield}}
        end
      end
    {% end %}
  {% end %}

  # Renders a template.
  #
  # Uses `ECR` to render the *template*, creating an `ATH::Response` with its rendered content and adding a `text/html` `content-type` header.
  #
  # The response can be modified further before returning it if needed.
  #
  # Variables used within the template must be defined within the action's body manually if they are not provided within the action's arguments.
  #
  # ```
  # # greeting.ecr
  # Greetings, <%= name %>!
  #
  # # example_controller.cr
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/{name}")]
  #   def greet(name : String) : ATH::Response
  #     render "greeting.ecr"
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /Fred # => Greetings, Fred!
  # ```
  macro render(template)
    Athena::Framework::Response.new ECR.render({{template}}), headers: HTTP::Headers{"content-type" => "text/html"}
  end

  # Renders a template within a layout.
  # ```
  # # layout.ecr
  # <h1>Content:</h1> <%= content -%>
  #
  # # greeting.ecr
  # Greetings, <%= name %>!
  #
  # # example_controller.cr
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/{name}")]
  #   def greet(name : String) : ATH::Response
  #     render "greeting.ecr", "layout.ecr"
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /Fred # => <h1>Content:</h1> Greetings, Fred!
  # ```
  macro render(template, layout)
    content = ECR.render {{template}}
    {{@type}}.render {{layout}}
  end
end
