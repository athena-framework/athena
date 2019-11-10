require "http/server"
require "amber_router"
require "CrSerializer"

require "./config/config"

require "./common/types"
require "./common/logger"

require "./di"

require "./routing/request_stack"
require "./routing/exceptions"

require "./routing/converters/*"
require "./routing/handlers/*"
require "./routing/parameters/*"
require "./routing/renderers/*"

# :nodoc:
macro halt(response, status_code, body)
  {{response}}.status_code = {{status_code}}
  {{response}}.print {{body}}
  {{response}}.headers.add "Content-Type", "application/json; charset=utf-8"
  {{response}}.close
  return
end

# :nodoc:
macro throw(status_code, body)
  response = ctx.response
  response.status_code = {{status_code}}
  response.print {{body}}
  response.headers.add "Content-Type", "application/json; charset=utf-8"
  response.close
  return
end

# Athena module containing elements for:
# * Defining routes.
# * Defining life-cycle callbacks.
# * Manage response serialization.
# * Handle param conversion.
module Athena::Routing
  # :nodoc:
  @@server : HTTP::Server?

  # :nodoc:
  # Fictional type representing no return.
  # See https://github.com/crystal-lang/crystal/issues/7698
  private record Noop

  # Defines a GET endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  # * cors : `String|Bool|Nil` - The `cors_group` to use for this specific action, or `false` to disable CORS.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Get(path: "/users")]
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  # * cors : `String|Bool|Nil` - The `cors_group` to use for this specific action, or `false` to disable CORS.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Post(path: "/users")]
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  # * cors : `String|Bool|Nil` - The `cors_group` to use for this specific action, or `false` to disable CORS.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Put(path: "/users")]
  # ```
  annotation Put; end

  # Defines a DELETE endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  # * cors : `String|Bool|Nil` - The `cors_group` to use for this specific action, or `false` to disable CORS.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Delete(path: "/users/:id")]
  # ```
  annotation Delete; end

  # Controls how params are converted.
  # ## Fields
  # * param : `String` - The param that should go through the conversion.
  # * type : `T` - The type the param should be converted to.
  # * converter : `Athena::Routing::Converters` - What converter to use for the conversion.  Can be `Converters::RequestBody`, `Converters::Exists`, `Converters::FormData`, or a custom defined converter.
  # * [pk_type] : `P` - The type the id should be resolved to before calling `T.find`.  Only required for `Converters::Exists`.
  #
  # ## Example
  # ```
  # @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  # ```
  annotation ParamConverter; end

  # Defines a callback that should be executed at a specific point in the request's life-cycle.
  # ## Fields
  # * event : `CallbackEvents` - The event that the callback should be executed at.
  # * only : `Array(String)` - Run the callback only for the provided actions.
  # * exclude : `Array(String)` - Run the callback for all actions except those provided.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse, only: ["users"])]
  # ```
  annotation Callback; end

  # Defines how the return value of an endpoint is displayed.
  # ## Fields
  # * groups : `Array(String)` - The serialization groups to apply to this endpoint.
  # See the [CrSerializer Docs](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md) for more info.
  # * renderer : `Athena::Routing::Renderers` - What renderer to use for the return value/object.  Default is `Renderers::JSONRenderer`.
  #
  # ## Example
  # ```
  # @[Athena::Routing::View(groups: ["admin", "default"])]
  # ```
  annotation View; end

  # Defines options that affect the whole controller.
  # ## Fields
  # * prefix : String - Apply a prefix to all actions within `self`.
  # * cors : `String|Bool|Nil` - The `cors_group` to use for all actions within this controller, or `false` to disable CORS for all actions.
  #
  # ## Example
  # ```
  # @[Athena::Routing::ControllerOptions(prefix: "calendar")]
  # class CalendarController < Athena::Routing::Controller
  #   # The rotue of this action would be `GET /calendar/events`
  #   @[Athena::Routing::Get(path: "events")]
  #   def self.events : String
  #     "events"
  #   end
  # end
  # ```
  annotation ControllerOptions; end

  # Events available during the request's life-cycle.
  enum CallbackEvents
    # Executes before the route's action has been executed.
    OnRequest

    # Executes after the route's action has been executed.
    OnResponse
  end

  # Parent class for all controllers.
  abstract class Controller
    # Exits the request with the given *status_code* and *body*.
    #
    # NOTE: declared on top level namespace but documented here
    # to be in the `Athena::Routing` module.
    macro throw(status_code, body)
      response = ctx.response
      response.status_code = {{status_code}}
      response.print {{body}}
      response.headers.add "Content-Type", "application/json"
      response.close
      return
    end

    # Handles exceptions that could occur when using Athena.  Will try to insert a *location* of the *exception* based on action name.
    # Otherwise location is unknown.
    # Throws a 500 if the error does not match any handler.
    #
    # Method can be defined on child classes for controller specific error handling.
    def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context, location : String = "unknown")
      case exception
      when Athena::Routing::Exceptions::AthenaException
        Athena.logger.notice "Unhandled AthenaException:", Crylog::LogContext{"code" => exception.code, "message" => exception.to_s}
        throw exception.code, exception.to_json
      when CrSerializer::Exceptions::ValidationException
        Athena.logger.notice exception.to_s
        throw 400, exception.to_json
      when ArgumentError
        Athena.logger.notice "Unhandled ArgumentError: #{exception.message}"
        throw 400, %({"code": 400, "message": "#{exception.message}"})
      when JSON::ParseException
        if msg = exception.message
          if parts = msg.match(/Expected (\w+) but was (\w+) .*[\r\n]*.+#(\w+)/)
            Athena.logger.notice "Expected '#{parts[3]}' to be #{parts[1]} but got #{parts[2]}"
            throw 400, %({"code": 400, "message": "Expected '#{parts[3]}' to be #{parts[1]} but got #{parts[2]}"})
          end

          if parts = msg.match(/Couldn't parse \((.*)\) from (.*) at/)
            Athena.logger.notice "Couldn't parse #{parts[1]} from '#{parts[2]}'"
            throw 400, %({"code": 400, "message": "Couldn't parse #{parts[1]} from '#{parts[2]}'"})
          end
        end

        Athena.logger.notice "Unhandled JSON::ParseException: #{exception.message}"
        throw 400, %({"code": 400, "message": "#{exception.message}"})
      else
        Crylog.logger.critical "Unhandled exception: #{exception.message} in #{self.name} at #{location}", Crylog::LogContext{"cause" => exception.cause.try(&.message), "cause_class" => exception.cause.class.name}
        # Otherwise throw a 500 if no other exception handlers are defined on any children
        throw 500, %({"code": 500, "message": "Internal Server Error"})
      end
    end
  end

  # :nodoc:
  abstract struct Action; end

  # :nodoc:
  private abstract struct CallbackBase; end

  # :nodoc:
  private record RouteDefinition,
    # The path that this action is responsible for.
    path : String,

    # The `cors_group` to use for this action.
    cors_group : String | Bool | Nil = nil

  # Contains metadata associated with a specific route.  Such as the controller to use, the required parameters, etc.
  #
  # NOTE: See the definition in code for documentation.
  private record RouteAction(A, R, C) < Action,
    # Action that gets executed for the route.
    action : A,

    # `RouteDefinition` for the route.
    route : RouteDefinition,

    # Any callbacks declared for this action.
    callbacks : Callbacks,

    # Method of the action.
    method : String,

    # Serialization groups set on this action.
    groups : Array(String),

    # Array of parameters defined on this path/action.
    params : Array(Athena::Routing::Parameters::Param)? = nil,

    # Renderer to use for the response of this action.
    renderer : R.class = R,

    # Controller this action belongs to.
    controller : C.class = C

  # :nodoc:
  private record Callbacks, on_response : Array(CallbackBase) = [] of CallbackBase, on_request : Array(CallbackBase) = [] of CallbackBase do
    def run_on_request_callbacks(ctx : HTTP::Server::Context, action : Action) : Nil
      @on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end
    end

    def run_on_response_callbacks(ctx : HTTP::Server::Context, action : Action) : Nil
      @on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end
    end
  end

  # :nodoc:
  private record CallbackEvent(E) < CallbackBase, event : E, only_actions : Array(String), exclude_actions : Array(String)

  # Stops the server.
  def self.stop
    if server = @@server
      server.close unless server.closed?
    else
      raise "Server not set"
    end
  end

  # Starts the HTTP server with the given *port*, *binding*, *ssl*, *reuse_port*, *handlers*.
  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server? | Bool? = nil, reuse_port : Bool = false, handlers : Array(HTTP::Handler) = [] of HTTP::Handler)
    # If no handlers are passed to `.run`; build out the default handlers,
    # otherwise just use user supplied handlers
    if handlers.empty?
      handlers = [
        Athena::Routing::Handlers::CorsHandler.new,
        Athena::Routing::Handlers::ActionHandler.new,
      ] of HTTP::Handler
    end

    # Validate the action handler is included
    raise "Handlers must include 'Athena::Routing::Handlers::ActionHandler'." if handlers.none? &.is_a? Athena::Routing::Handlers::ActionHandler

    # Insert the RouteHandler automatically
    handlers.unshift Athena::Routing::Handlers::RouteHandler.new

    # Configure the loggers
    Athena.configure_logger

    # Define the server
    @@server = HTTP::Server.new do |ctx|
      # Instantiate a new instance of the container so that
      # the container objects do not bleed between requests
      Fiber.current.container = Athena::DI::ServiceContainer.new

      # Build out and kick off the process
      HTTP::Server.build_middleware(handlers, nil)
      handlers.first.call ctx
    end

    if Athena.environment != "test"
      Signal::INT.trap do
        Athena::Routing.stop
        exit
      end

      Athena.logger.info "Athena is leading the way on #{binding}:#{port} in the #{Athena.environment} environment"
    end

    unless @@server.not_nil!.each_address { |_| break true }
      {% if flag?(:without_openssl) %}
        @@server.not_nil!.bind_tcp(binding, port, reuse_port: reuse_port)
      {% else %}
        if ssl
          @@server.not_nil!.bind_tls(binding, port, ssl, reuse_port: reuse_port)
        else
          @@server.not_nil!.bind_tcp(binding, port, reuse_port: reuse_port)
        end
      {% end %}
    end

    @@server.not_nil!.listen
  rescue ex : CrSerializer::Exceptions::ValidationException
    raise ex.to_s
  end
end
