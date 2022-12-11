require "ecr"
require "http/server"
require "json"

require "athena-config"
require "athena-console"
require "athena-dependency_injection"
require "athena-event_dispatcher"
require "athena-negotiation"

require "./action"
require "./annotations"
require "./binary_file_response"
require "./controller"
require "./controller_resolver"
require "./error_renderer_interface"
require "./error_renderer"
require "./header_utils"
require "./logging"
require "./parameter_bag"
require "./param_converter"
require "./redirect_response"
require "./response"
require "./response_headers"
require "./request"
require "./request_body_converter"
require "./request_store"
require "./route_handler"
require "./streamed_response"
require "./time_converter"

require "./arguments/**"
require "./commands/*"
require "./config/*"
require "./compiler_passes/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./parameters/*"
require "./params/*"
require "./view/*"

require "./ext/console"
require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/negotiation"
require "./ext/routing"
require "./ext/serializer"
require "./ext/validator"

# Convenience alias to make referencing `Athena::Framework` types easier.
alias ATH = Athena::Framework

# Convenience alias to make referencing `Athena::Framework::Annotations` types easier.
alias ATHA = ATH::Annotations

# See the [external documentation](https://athenaframework.org) for an introduction to `Athena`.
#
# Also checkout the [Components](/components) for an overview of how `Athena` is designed.
module Athena::Framework
  VERSION = "0.17.1"

  # The `AED::Event` that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Custom events can also be defined and dispatched within a controller, listener, or some other service.
  #
  # See each specific event and the [external documentation](/components/event_dispatcher/) for more information.
  module Events; end

  # Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `ATH::Exceptions::HTTPException`.
  #
  # When an exception is raised, Athena emits the `ATH::Events::Exception` event to allow an opportunity for it to be handled. If the exception goes unhandled, i.e. no listener set
  # an `ATH::Response` on the event, then the request is finished and the exception is reraised. Otherwise, that response is returned, setting the status and merging the headers on the exceptions
  # if it is an `ATH::Exceptions::HTTPException`. See `ATH::Listeners::Error` and `ATH::ErrorRendererInterface` for more information on how exceptions are handled by default.
  #
  # To provide the best response to the client, non `ATH::Exceptions::HTTPException` should be rescued and converted into a corresponding `ATH::Exceptions::HTTPException`.
  # Custom HTTP errors can also be defined by inheriting from `ATH::Exceptions::HTTPException` or a child type. A use case for this could be allowing for additional data/context to be included
  # within the exception that ultimately could be used in a `ATH::Events::Exception` listener.
  module Exceptions; end

  # The `AED::EventListenerInterface` that act upon `ATH::Events` to handle a request. Custom listeners can also be defined, see `AED::EventListenerInterface`.
  #
  # See each listener and the [external documentation](/components/event_dispatcher/) for more information.
  module Listeners
    # The tag name for Athena event listeners.
    TAG = "athena.event_dispatcher.listener"
  end

  # Namespace for types related to controller action arguments.
  #
  # See `ATH::Arguments::ArgumentMetadata`.
  module Arguments; end

  # The default `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`s that will handle resolving controller action arguments from a request (or other source).
  # Custom argument value resolvers can also be defined, see `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`.
  #
  # NOTE: In order for `Athena::Framework` to pick up your custom value resolvers, be sure to `ADI::Register` it as a service, and tag it as `ATH::Arguments::Resolvers::TAG`.
  # A `priority` field can also be optionally included in the annotation, the higher the value the sooner in the array it'll be when injected.
  #
  # See each resolver for more detailed information.
  module Arguments::Resolvers
    # The tag name for `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`s.
    TAG = "athena.argument_value_resolver"
  end

  # Namespace for types related to request parameter processing.
  #
  # See `ATHA::QueryParam` and `ATHA::RequestParam`.
  module Params; end

  # :nodoc:
  module CompilerPasses; end

  # Namespace for the built in `Athena::Console` commands that come bundled with the framework.
  module Commands; end

  # Runs an `HTTP::Server` listening on the given *port* and *host*.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   def root : String
  #     "At the index"
  #   end
  # end
  #
  # ATH.run
  # ```
  #
  # *prepend_handlers* can be used to execute an array of `HTTP::Handler` _before_ Athena takes over.
  # This can be useful to provide backwards compatibility with existing handlers until they can ported to Athena concepts,
  # or for supporting things Athena does not support, such as WebSockets.
  #
  # See `ATH::Controller` for more information on defining controllers/route actions.
  def self.run(
    port : Int32 = 3000,
    host : String = "0.0.0.0",
    reuse_port : Bool = false,
    ssl_context : OpenSSL::SSL::Context::Server? = nil,
    *,
    prepend_handlers : Array(HTTP::Handler) = [] of HTTP::Handler
  ) : Nil
    ATH::Server.new(port, host, reuse_port, ssl_context, prepend_handlers).start
  end

  # :nodoc:
  #
  # Currently an implementation detail. In the future could be exposed to allow having separate "groups" of controllers that a `Server` instance handles.
  struct Server
    def initialize(
      @port : Int32 = 3000,
      @host : String = "0.0.0.0",
      @reuse_port : Bool = false,
      @ssl_context : OpenSSL::SSL::Context::Server? = nil,
      prepend_handlers handlers : Array(HTTP::Handler) = [] of HTTP::Handler
    )
      handler_proc = HTTP::Handler::HandlerProc.new do |context|
        # Reinitialize the container since keep-alive requests reuse the same fiber.
        Fiber.current.container = ADI::ServiceContainer.new

        handler = ADI.container.athena_route_handler

        # Convert the raw `HTTP::Request` into an `ATH::Request` instance.
        request = ATH::Request.new context.request

        # Handle the request.
        athena_response = handler.handle request

        # Send the response based on the current context.
        athena_response.send request, context.response

        # Emit the terminate event now that the response has been sent.
        handler.terminate request, athena_response
      end

      @server = if handlers.empty?
                  HTTP::Server.new &handler_proc
                else
                  HTTP::Server.new handlers, &handler_proc
                end
    end

    def stop : Nil
      @server.close unless @server.closed?
    end

    def start : Nil
      {% if flag?(:without_openssl) %}
        @server.bind_tcp @host, @port, reuse_port: @reuse_port
      {% else %}
        if ssl = @ssl_context
          @server.bind_tls @host, @port, ssl, @reuse_port
        else
          @server.bind_tcp @host, @port, reuse_port: @reuse_port
        end
      {% end %}

      # Handle exiting correctly on stop/kill signals
      Signal::INT.trap { self.stop }
      Signal::TERM.trap { self.stop }

      Log.info { %(Server has started and is listening at #{@ssl_context ? "https" : "http"}://#{@server.addresses.first}) }

      @server.listen
    end
  end
end
