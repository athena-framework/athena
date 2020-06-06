require "ecr"
require "http/server"
require "json"

require "amber_router"
require "athena-config"
require "athena-dependency_injection"
require "athena-event_dispatcher"

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

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Athena's Routing component, `ART` for short, provides an event based framework for converting a request into a response
# and includes various abstractions/useful types to make that process easier.
#
# Athena is an event based framework; meaning it emits `ART::Events` that are acted upon to handle the request.
# Athena also utilizes `Athena::DependencyInjection` to provide a service container layer.  The service container layer
# allows a project to share/inject useful objects between various types, such as a custom `AED::EventListenerInterface`, `ART::Controller`, or `ART::ParamConverterInterface`.
# See the corresponding types for more information.
#
# * See `ART::Controller` for documentation on defining controllers/route actions.
# * See `ART::Config` for documentation on configuration options available for the Routing component.
# * See `ART::Events` for documentation on the events that can be listened on during the request's life-cycle.
# * See `ART::ParamConverterInterface` for documentation on using param converters.
# * See `ART::Exceptions` for documentation on exception handling.
module Athena::Routing
  protected class_getter route_resolver : ART::RouteResolver { ART::RouteResolver.new }

  # The `AED::Event` that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Athena adds a `HTTP::Request#attributes` getter that returns a `Hash(String, Bool | Int32 | String | Float64 | Nil)` which can be used to store simple information that can be used later.
  #
  # See each specific event for more detailed information.
  module Athena::Routing::Events; end

  # Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `ART::Exceptions::HTTPException`.
  #
  # When an exception is raised, Athena emits the `ART::Events::Exception` event to allow an opportunity for it to be handled.  If the exception goes unhanded, i.e. no listener set
  # an `ART::Response` on the event, then the request is finished and the exception is reraised.  Otherwise, that response is returned, setting the status and merging the headers on the exceptions
  # if it is an `ART::Exceptions::HTTPException`. See `ART::Listeners::Error` and `ART::ErrorRendererInterface` for more information on how exceptions are handled by default.
  #
  # To provide the best response to the client, non `ART::Exceptions::HTTPException` should be rescued and converted into a corresponding `ART::Exceptions::HTTPException`.
  # Custom HTTP errors can also be defined by inheriting from `ART::Exceptions::HTTPException`.  A use case for this could be allowing for additional data/context to be included
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
  # See `ART::Route`.
  abstract struct Action; end

  # Represents an endpoint within the application.
  #
  # Includes metadata about the endpoint, such as its controller, arguments, return type, and the action should be executed.
  struct Route(Controller, ActionType, ReturnType, ArgTypeTuple, ArgumentsType) < Action
    # The HTTP method associated with `self`.
    getter method : String

    # The name of the the controller action related to `self`.
    getter action_name : String

    # An `Array(ART::Arguments::ArgumentMetadata)` that `self` requires.
    getter arguments : ArgumentsType

    # An `Array(ART::ParamConverterInterface::ConfigurationInterface)` representing the `ART::ParamConverter`s applied to `self.
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

    # Executes `#action` with the provided *arguments* array.
    def execute(arguments : Array) : ReturnType
      @action.call.call *{{ArgTypeTuple.type_vars.empty? ? "Tuple.new".id : ArgTypeTuple}}.from arguments
    end
  end

  # Runs an `HTTP::Server` listening on the given *port* and *host*.
  #
  # ```
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
  def self.run(port : Int32 = 3000, host : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server | Bool | Nil = nil, reuse_port : Bool = false)
    ART::Server.new(port, host, ssl, reuse_port).start
  end

  # :nodoc:
  #
  # Currently an implementation detail.  In the future could be exposed to allow having separate "groups" of controllers that a `Server` instance handles.
  struct Server
    def initialize(@port : Int32 = 3000, @host : String = "0.0.0.0", @ssl : OpenSSL::SSL::Context::Server | Bool | Nil = nil, @reuse_port : Bool = false)
      # Define the server
      @server = HTTP::Server.new do |context|
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

      @server.listen
    end
  end
end
