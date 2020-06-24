require "ecr"
require "http/server"
require "json"

require "amber_router"
require "athena-config"
require "athena-dependency_injection"
require "athena-event_dispatcher"
require "athena-serializer"

require "./annotations"
require "./controller"
require "./error_renderer_interface"
require "./error_renderer"
require "./logging"
require "./parameter_bag"
require "./param_converter_interface"
require "./redirect_response"
require "./response"
require "./request_store"
require "./route_handler"
require "./route_resolver"
require "./time_converter"
require "./view"

require "./arguments/**"
require "./config/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"

require "./ext/configuration_resolver"
require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/request"
require "./ext/serializer"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Athena is a set of independent, reusable [components](https://github.com/athena-framework) with the goal of providing
# a set of high quality, flexible, and robust framework building blocks.  These components could be used on their own,
# or outside of the Athena ecosystem, to prevent every framework/project from needing to "reinvent the wheel."
#
# The `Athena::Routing` component is the result of combining these components into a single robust, flexible, and self-contained framework.
#
# ## Getting Started
#
# Athena does not have any other dependencies outside of `Crystal`/`Shards`.
# It is designed in such a way to be non-intrusive, and not require a strict organizational convention in regards to how a project is setup;
# this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.
#
# ### Installation
#
# Add the dependency to your `shard.yml`:
#
# ```yaml
# dependencies:
#   athena:
#     github: athena-framework/athena
#     version: 0.9.0
# ```
#
# Run `shards install`.  This will install Athena and its required dependencies.
#
# ### Usage
#
# Athena has a goal of being easy to start using for simple use cases, while still allowing flexibility/customizability for larger more complex use cases.
#
# #### Routing
#
# Athena is a MVC based framework, as such, the logic to handle a given route is defined in an `ART::Controller` class.
#
# ```
# require "athena"
#
# # Define a controller
# class ExampleController < ART::Controller
#   # Define an action to handle the related route
#   @[ART::Get("/")]
#   def index : String
#     "Hello World"
#   end
#
#   # The macro DSL can also be used
#   get "/" do
#     "Hello World"
#   end
# end
#
# # Run the server
# ART.run
#
# # GET / # => Hello World
# ```
# Annotations applied to the methods are used to define the HTTP method this method handles, such as `ART::Get` or `ART::Post`.  A macro DSL also exists to make them a bit less verbose;
# `ART::Controller.get` or `ART::Controller.post`.  The `ART::Route` annotation can also be used to define custom `HTTP` methods.
#
# Controllers are simply classes and routes are simply methods.  Controllers and actions can be documented/tested as you would any Crystal class/method.
#
# #### Route Parameters
#
# Parameters, such as path/query parameters, are also defined via annotations and map directly to the method's arguments.
#
# ```
# require "athena"
#
# class ExampleController < ART::Controller
#   @[ART::QueryParam("negative")]
#   @[ART::Get("/add/:value1/:value2")]
#   def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
#     sum = value1 + value2
#     negative ? -sum : sum
#   end
# end
#
# ART.run
#
# # GET /add/2/3               # => 5
# # GET /add/5/5?negative=true # => -10
# # GET /add/foo/12            # => {"code":422,"message":"Required parameter 'value1' with value 'foo' could not be converted into a valid 'Int32'"}
# ```
#
# Arguments are converted to their expected types if possible, otherwise an error response is automatically returned.
# The values are provided directly as method arguments, thus preventing the need for `env.params.url["name"]` and any boilerplate related to it.
# Just like normal methods arguments, default values can be defined. The method's return type adds some type safety to ensure the expected value is being returned.
#
# Restricting an action argument to `HTTP::Request` will provide the raw request object, which can be used to retrieve the request data.
# This approach is fine for simple or one-off endpoints, however for more complex/common request data processing, it is suggested to create
# a [Param Converter](./Routing.html#param-converters).
#
# ```
# require "athena"
#
# class ExampleController < ART::Controller
#   @[ART::Post("/data")]
#   def data(request : HTTP::Request) : String?
#     request.body.try &.gets_to_end
#   end
# end
#
# ART.run
#
# # POST /data body: "foo--bar" # => "foo--bar"
# ```
#
# An `ART::Response` can also be used in order to fully customize the response, such as returning a specific status code, adding some one-off headers, or saving memory by directly
# writing the response value to the Response IO.
#
# ```
# require "athena"
# require "mime"
#
# class ExampleController < ART::Controller
#   # A GET endpoint returning an `ART::Response`.
#   @[ART::Get(path: "/css")]
#   def css : ART::Response
#     ART::Response.new ".some_class { color: blue; }", headers: HTTP::Headers{"content-type" => MIME.from_extension(".css")}
#   end
# end
#
# ART.run
#
# # GET /css # => ".some_class { color: blue; }"
# ```
#
# An `ART::Events::View` is emitted if the returned value is _NOT_ an `ART::Response`.  By default, non `ART::Response`s are JSON serialized.
# However, this event can be listened on to customize how the value is serialized.
#
# #### Error Handling
#
# Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `ART::Exceptions::HTTPException`.
# Custom `HTTP` errors can also be defined by inheriting from `ART::Exceptions::HTTPException` or a child type.
# A use case for this could be allowing additional data/context to be included within the exception.
#
# Non `ART::Exceptions::HTTPException` exceptions are represented as a `500 Internal Server Error`.
#
# When an exception is raised, Athena emits the `ART::Events::Exception` event to allow an opportunity for it to be handled.
# By default these exceptions will return a `JSON` serialized version of the exception, via `ART::ErrorRenderer`, that includes the message and code; with the proper response status set.
# If the exception goes unhandled, i.e. no listener set an `ART::Response` on the event, then the request is finished and the exception is reraised.
#
# ```
# require "athena"
#
# class ExampleController < ART::Controller
#   get "divide/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
#     num1 // num2
#   end
#
#   get "divide_rescued/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
#     num1 // num2
#     # Rescue a non `ART::Exceptions::HTTPException`
#   rescue ex : DivisionByZeroError
#     # in order to raise an `ART::Exceptions::HTTPException` to provide a better error message to the client.
#     raise ART::Exceptions::BadRequest.new "Invalid num2:  Cannot divide by zero"
#   end
# end
#
# ART.run
#
# # GET /divide/10/0 # => {"code":500,"message":"Internal Server Error"}
# # GET /divide_rescued/10/0 # => {"code":400,"message":"Invalid num2:  Cannot divide by zero"}
# ```
#
# ### Advanced Usage
#
# Athena also ships with some more advanced features to provide more flexibility/control for an application.
# These features may not be required for a simple application; however as the application grows they may become more useful.
#
# #### Param Converters
# `ART::ParamConverterInterface`s allow complex types to be supplied to an action via its arguments.
# An example of this could be extracting the id from `/users/10`, doing a DB query to lookup the user with the PK of `10`, then providing the full user object to the action.
# Param converters abstract any custom parameter handling that would otherwise have to be done in each action.
#
# ```
# require "athena"
#
# @[ADI::Register]
# struct MultiplyConverter < ART::ParamConverterInterface
#   # :inherit:
#   def apply(request : HTTP::Request, configuration : Configuration) : Nil
#     arg_name = configuration.name
#
#     return unless request.attributes.has? arg_name
#
#     value = request.attributes.get arg_name, Int32
#     request.attributes.set arg_name, value * 2, Int32
#   end
# end
#
# class ParamConverterController < ART::Controller
#   @[ART::Get(path: "/multiply/:num")]
#   @[ART::ParamConverter("num", converter: MultiplyConverter)]
#   def multiply(num : Int32) : Int32
#     num
#   end
# end
#
# ART.run
#
# # GET / multiply/3 # => 6
# ```
#
# #### Middleware
#
# Athena is an event based framework; meaning it emits `ART::Events` that are acted upon internally to handle the request.
# These same events can also be listened on by custom listeners, via `AED::EventListenerInterface`, in order to tap into the life-cycle of the request.
# An example use case of this could be: adding common headers, cookies, compressing the response, authentication, or even returning a response early like `ART::Listeners::CORS`.
#
# ```
# require "athena"
#
# @[ADI::Register]
# struct CustomListener
#   include AED::EventListenerInterface
#
#   # Specify that we want to listen on the `Response` event.
#   # The value of the hash represents this listener's priority;
#   # the higher the value the sooner it gets executed.
#   def self.subscribed_events : AED::SubscribedEvents
#     AED::SubscribedEvents{
#       ART::Events::Response => 25,
#     }
#   end
#
#   def call(event : ART::Events::Response, dispatcher : AED::EventDispatcherInterface) : Nil
#     event.response.headers["FOO"] = "BAR"
#   end
# end
#
# class ExampleController < ART::Controller
#   get "/" do
#     "Hello World"
#   end
# end
#
# ART.run
#
# # GET / # => Hello World (with `FOO => BAR` header)
# ```
#
# #### Dependency Injection
#
# Athena utilizes `Athena::DependencyInjection` to provide a service container layer.
# DI allows controllers/other services to be decoupled from specific implementations.
# This makes testing easier as test implementations of the dependencies can be used.
#
# In Athena, most everything is a service that belongs to the container, which is unique to the current request.  The major benefit of this is it allows various types to be shared amongst the services.
# For example, allowing param converters, controllers, etc. to have access to the current request via the `ART::RequestStore` service.
#
# Another example would be defining a service to store a `UUID` to represent the current request, then using this service to include the UUID in the response headers.
#
# ```
# require "athena"
# require "uuid"
#
# @[ADI::Register]
# struct RequestIDStore
#   HEADER_NAME = "X-Request-ID"
#
#   # Inject `ART::RequestStore` in order to have access to the current request's headers.
#   def initialize(@request_store : ART::RequestStore); end
#
#   property request_id : String? = nil do
#     # Check the request store for a request.
#     request = @request_store.request?
#
#     # If there is a request and it has the Header,
#     if request && request.headers.has_key? HEADER_NAME
#       # use that ID.
#       request.headers[HEADER_NAME]
#     else
#       # otherwise generate a new one.
#       UUID.random.to_s
#     end
#   end
# end
#
# @[ADI::Register]
# struct RequestIDListener
#   include AED::EventListenerInterface
#
#   def self.subscribed_events : AED::SubscribedEvents
#     AED::SubscribedEvents{
#       ART::Events::Response => 0,
#     }
#   end
#
#   def initialize(@request_id_store : RequestIDStore); end
#
#   def call(event : ART::Events::Response, dispatcher : AED::EventDispatcherInterface) : Nil
#     # Set the request ID as a response header
#     event.response.headers[RequestIDStore::HEADER_NAME] = @request_id_store.request_id
#   end
# end
#
# class ExampleController < ART::Controller
#   get "/" do
#     ""
#   end
# end
#
# ART.run
#
# # GET / # => (`X-Request-ID => 07bda224-fb1d-4b82-b26c-19d46305c7bc` header)
# ```
#
# The main benefit of having `RequestIDStore` and not doing `event.response.headers[RequestIDStore::HEADER_NAME] = UUID.random.to_s` directly is that the value could be used in other places.
# Say for example you have a route that enqueues messages to be processed asynchronously.  The `RequestIDStore` could be inject into that controller/service in order to include the same `UUID`
# within the message in order to expand tracing to async contexts.  Without DI, like in other frameworks, there would not be an easy to way to share the same instance of an object between
# different types.  It also wouldn't be easy to have access to data outside the request context.
#
# DI is also what "wires" everything together.  For example, say there is an external shard that defines a listener.  All that would be required to use that listener is install and require the shard,
# DI takes care of the rest.  This is much easier and more flexible than needing to update code to add a new `HTTP::Handler` instance to an array.
module Athena::Routing
  protected class_getter route_resolver : ART::RouteResolver { ART::RouteResolver.new }

  # The `AED::Event` that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Custom events can also be defined and dispatched within a controller, listener, or some other service.
  #
  # See each specific event for more detailed information.
  module Athena::Routing::Events; end

  # Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `ART::Exceptions::HTTPException`.
  #
  # When an exception is raised, Athena emits the `ART::Events::Exception` event to allow an opportunity for it to be handled.  If the exception goes unhandled, i.e. no listener set
  # an `ART::Response` on the event, then the request is finished and the exception is reraised.  Otherwise, that response is returned, setting the status and merging the headers on the exceptions
  # if it is an `ART::Exceptions::HTTPException`. See `ART::Listeners::Error` and `ART::ErrorRendererInterface` for more information on how exceptions are handled by default.
  #
  # To provide the best response to the client, non `ART::Exceptions::HTTPException` should be rescued and converted into a corresponding `ART::Exceptions::HTTPException`.
  # Custom HTTP errors can also be defined by inheriting from `ART::Exceptions::HTTPException` or a child type.  A use case for this could be allowing for additional data/context to be included
  # within the exception that ultimately could be used in a `ART::Events::Exception` listener.
  module Athena::Routing::Exceptions; end

  # The `AED::EventListenerInterface` that act upon `ART::Events` to handle a request.  Custom listeners can also be defined, see `AED::EventListenerInterface`.
  #
  # See each listener for more detailed information.
  module Athena::Routing::Listeners
    # The tag name for Athena event listeners.
    TAG = "athena.event_dispatcher.listener"

    # Apply `TAG` to all `AED::EventListenerInterface` instances automatically.
    ADI.auto_configure AED::EventListenerInterface, {tags: [ART::Listeners::TAG]}
  end

  # Namespace for types related to controller action arguments.
  #
  # See `ART::Arguments::ArgumentMetadata`.
  module Athena::Routing::Arguments; end

  # The default `ART::Arguments::Resolvers::ArgumentValueResolverInterface`s that will handle resolving controller action arguments from a request (or other source).
  # Custom argument value resolvers can also be defined, see `ART::Arguments::Resolvers::ArgumentValueResolverInterface`.
  #
  # NOTE: In order for `Athena::Routing` to pick up your custom value resolvers, be sure to `ADI::Register` it as a service, and tag it as `ART::Arguments::Resolvers::TAG`.
  # A `priority` field can also be optionally included in the annotation, the higher the value the sooner in the array it'll be when injected.
  #
  # See each resolver for more detailed information.
  module Athena::Routing::Arguments::Resolvers
    # The tag name for `ART::Arguments::Resolvers::ArgumentValueResolverInterface`s.
    TAG = "athena.argument_value_resolver"
  end

  # Parent type of a route just used for typing.
  #
  # See `ART::Action`.
  abstract struct ActionBase; end

  # Represents an endpoint within the application.
  #
  # Includes metadata about the endpoint, such as its controller, arguments, return type, and the action should be executed.
  struct Action(Controller, ActionType, ReturnType, ArgTypeTuple, ArgumentsType) < ActionBase
    # The HTTP method associated with `self`.
    getter method : String

    # The name of the the controller action related to `self`.
    getter action_name : String

    # An `Array(ART::Arguments::ArgumentMetadata)` that `self` requires.
    getter arguments : ArgumentsType

    # An `Array(ART::ParamConverterInterface::ConfigurationInterface)` representing the `ART::ParamConverter`s applied to `self`.
    getter param_converters : Array(ART::ParamConverterInterface::ConfigurationInterface)

    def initialize(
      @action : ActionType,
      @action_name : String,
      @method : String,
      @arguments : ArgumentsType,
      @param_converters : Array(ART::ParamConverterInterface::ConfigurationInterface),
      # Don't bother making these ivars since we just need them to set the generic types
      _controller : Controller.class,
      _return_type : ReturnType.class,
      _arg_types : ArgTypeTuple.class
    )
    end

    # The type that `self`'s route should return.
    def return_type : ReturnType.class
      ReturnType
    end

    # The `ART::Controller` that includes `self`.
    def controller : Controller.class
      Controller
    end

    # Executes the action related to `self` with the provided *arguments* array.
    def execute(arguments : Array) : ReturnType
      @action.call.call *{{ArgTypeTuple.type_vars.empty? ? "Tuple.new".id : ArgTypeTuple}}.from arguments
    end
  end

  # Runs an `HTTP::Server` listening on the given *port* and *host*.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   def root : String
  #     "At the index"
  #   end
  # end
  #
  # ART.run
  # ```
  # See `ART::Controller` for more information on defining controllers/route actions.
  def self.run(port : Int32 = 3000, host : String = "0.0.0.0", reuse_port : Bool = false) : Nil
    ART::Server.new(port, host, reuse_port).start
  end

  # :nodoc:
  #
  # Currently an implementation detail.  In the future could be exposed to allow having separate "groups" of controllers that a `Server` instance handles.
  struct Server
    def initialize(@port : Int32 = 3000, @host : String = "0.0.0.0", @reuse_port : Bool = false)
      # Define the server
      @server = HTTP::Server.new do |context|
        # Reinitialize the container since keep-alive requests reuse the same fiber
        Fiber.current.container = ADI::ServiceContainer.new

        # Handle the request
        ADI.container.athena_routing_route_handler.handle context
      end
    end

    def stop : Nil
      @server.close unless @server.closed?
    end

    def start : Nil
      @server.bind_tcp(@host, @port, reuse_port: @reuse_port)

      # Handle exiting correctly on stop/kill signals
      Signal::INT.trap { self.stop }
      Signal::TERM.trap { self.stop }

      Log.info { "Server has started and is listening at http://#{@server.addresses.first}" }

      @server.listen
    end
  end
end
