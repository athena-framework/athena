require "ecr"
require "http/server"
require "json"

require "amber_router"
require "athena-config"
require "athena-dependency_injection"
require "athena-event_dispatcher"

require "./action"
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
require "./time_converter"

require "./arguments/**"
require "./config/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./params/*"
require "./routing/*"

require "./ext/configuration_resolver"
require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/request"
require "./ext/serializer"
require "./ext/validator"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Athena is a set of independent, reusable [components](https://github.com/athena-framework) with the goal of providing
# a set of high quality, flexible, and robust framework building blocks.  These components could be used on their own,
# or outside of the Athena ecosystem, to prevent every framework/project from needing to "reinvent the wheel."
#
# The `Athena::Routing` component is the result of combining these components into a single robust, flexible, and self-contained framework.
module Athena::Routing
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

  # Namespace for types related to request parameter processing.
  #
  # See `ART::QueryParam` and `ART::RequestParam`.
  module Athena::Routing::Params; end

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
