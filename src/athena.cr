require "ecr"
require "http/server"
require "json"

require "amber_router"
require "athena-config"
require "athena-dependency_injection"
require "athena-event_dispatcher"
require "athena-negotiation"

require "./action"
require "./annotations"
require "./binary_file_response"
require "./controller"
require "./error_renderer_interface"
require "./error_renderer"
require "./header_utils"
require "./logging"
require "./parameter_bag"
require "./param_converter_interface"
require "./redirect_response"
require "./response"
require "./request_store"
require "./route_handler"
require "./streamed_response"
require "./time_converter"

require "./arguments/**"
require "./config/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./parameters/*"
require "./params/*"
require "./routing/*"
require "./view/*"

require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/http"
require "./ext/negotiation"
require "./ext/serializer"
require "./ext/validator"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Convenience alias to make referencing `Athena::Routing::Annotations` types easier.
alias ARTA = ART::Annotations

# See the [external documentation](https://athenaframework.org) for an introduction to `Athena`.
#
# Also checkout the [Components](/components) for an overview of how `Athena` is designed.
module Athena::Routing
  # The `AED::Event` that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Custom events can also be defined and dispatched within a controller, listener, or some other service.
  #
  # See each specific event and the [external documentation](/components/event_dispatcher/) for more information.
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
  # See each listener and the [external documentation](/components/event_dispatcher/) for more information.
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
  # See `ARTA::QueryParam` and `ARTA::RequestParam`.
  module Athena::Routing::Params; end

  # Runs an `HTTP::Server` listening on the given *port* and *host*.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ART::Controller
  #   @[ARTA::Get("/")]
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
        # Reinitialize the container since keep-alive requests reuse the same fiber.
        Fiber.current.container = ADI::ServiceContainer.new

        handler = ADI.container.athena_routing_route_handler

        # Handle the request.
        athena_response = handler.handle context.request

        # Send the respones based on the current context.
        athena_response.send context

        # Emit the terminate event now that the response has been sent.
        handler.terminate context.request, athena_response
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
