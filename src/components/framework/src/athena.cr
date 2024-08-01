require "ecr"
require "http/server"
require "json"

require "athena-clock"
require "athena-console"
require "athena-dependency_injection"
require "athena-event_dispatcher"
require "athena-negotiation"

require "./abstract_bundle"
require "./action"
require "./annotations"
require "./bundle"
require "./binary_file_response"
require "./controller"
require "./controller_resolver"
require "./error_renderer_interface"
require "./error_renderer"
require "./header_utils"
require "./logging"
require "./parameter_bag"
require "./redirect_response"
require "./response"
require "./response_headers"
require "./request"
require "./request_matcher"
require "./request_store"
require "./route_handler"
require "./streamed_response"

require "./ext/serializer"

require "./commands/*"
require "./controller/**"
require "./compiler_passes/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./params/*"
require "./request_matcher/*"
require "./view/*"

require "./ext/clock"
require "./ext/console"
require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/routing"
require "./ext/validator"

# Convenience alias to make referencing `Athena::Framework` types easier.
alias ATH = Athena::Framework

# Convenience alias to make referencing `Athena::Framework::Annotations` types easier.
alias ATHA = ATH::Annotations

# Convenience alias to make referencing `ATH::Controller::ValueResolvers` types easier.
alias ATHR = ATH::Controller::ValueResolvers

module Athena::Framework
  VERSION = "0.19.2"

  # The name of the environment variable used to determine Athena's current environment.
  ENV_NAME = "ATHENA_ENV"

  # Returns the current environment Athena is in based on `ENV_NAME`.  Defaults to `development` if not defined.
  def self.environment : String
    ENV[ENV_NAME]? || "development"
  end

  # This type includes all of the built-in resolvers that Athena uses to try and resolve an argument for a particular controller action parameter.
  # They run in the following order:
  #
  # 1. `ATHR::Enum` (105) - Attempts to resolve a value from `ATH::Request#attributes` into an enum member of the related type.
  # Works well in conjunction with `ART::Requirement::Enum`.
  #
  # 1. `ATHR::Time` (105) - Attempts to resolve a value from the request attributes into a `::Time` instance,
  # defaulting to [RFC 3339](https://crystal-lang.org/api/Time.html#parse_rfc3339%28time:String%29-class-method).
  # Format/location can be customized via the `ATHA::MapTime` annotation.
  #
  # 1. `ATHR::UUID` (105) - Attempts to resolve a value from the request attributes into a `::UUID` instance.
  #
  # 1. `ATHR::RequestBody` (105) - If enabled, attempts to deserialize the request body into the type of the related parameter, running any validations, if any.
  #
  # 1. `ATHR::RequestAttribute` (100) - Provides a value stored in `ATH::Request#attributes` if one with the same name as the action parameter exists.
  #
  # 1. `ATHR::Request` (50) - Provides the current `ATH::Request` if the related parameter is typed as such.
  #
  # 1. `ATHR::DefaultValue` (-100) - Provides the default value of the parameter if it has one, or `nil` if it is nilable.
  #
  # See each resolver for more detailed information.
  # Custom resolvers may also be defined.
  # See `ATHR::Interface` for more information.
  module Controller::ValueResolvers; end

  # The `AED::Event` that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Custom events can also be defined and dispatched within a controller, listener, or some other service.
  #
  # See each specific event and the [Getting Started](/getting_started/middleware) docs for more information.
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

  # The event listeners that act upon `ATH::Events` to handle a request.
  # Custom listeners can also be defined, see `AEDA::AsEventListener`.
  #
  # See each listener and the [Getting Started](/getting_started/middleware) docs for more information.
  module Listeners; end

  # Namespace for types related to request parameter processing.
  #
  # See `ATHA::QueryParam` and `ATHA::RequestParam`.
  module Params; end

  # :nodoc:
  module CompilerPasses; end

  # Namespace for the built in `Athena::Console` commands that come bundled with the framework.
  # Currently it provides:
  #
  # - `ATH::Commands::DebugEventDispatcher` - Display configured listeners for an application
  # - `ATH::Commands::DebugRouter` - Display current routes for an application
  # - `ATH::Commands::DebugRouterMatch` - Simulate a path match to see which route, if any, would handle it
  #
  # See each command class for more information.
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

  # Runs an `ATH::Console::Application` as the entrypoint of `Athena::Console`.
  #
  # Checkout the [Getting Started](/getting_started/commands) docs for more information.
  def self.run_console : Nil
    ADI.container.athena_console_application.run
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

      # Handle exiting correctly on interrupt signals
      Process.on_terminate { self.stop }

      Log.info { %(Server has started and is listening at #{@ssl_context ? "https" : "http"}://#{@server.addresses.first}) }

      @server.listen
    end
  end
end

ATH.register_bundle ATH::Bundle
