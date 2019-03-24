require "http/server"
require "amber_router"
require "json"
require "CrSerializer"

require "./config/config"

require "./common/types"

require "./routing/converters"
require "./routing/exceptions"
require "./routing/renderers"
require "./routing/handlers/handler"
require "./routing/handlers/*"

# Athena module containing elements for:
# * Defining routes.
# * Defining life-cycle callbacks.
# * Manage response serialization.
# * Handle param conversion.
module Athena::Routing
  # Defines a GET endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Get(path: "/users")]
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Post(path: "/users")]
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Put(path: "/users")]
  # ```
  annotation Put; end

  # Defines a DELETE endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
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
  #
  # ## Example
  # ```
  # @[Athena::Routing::ControllerOptions(prefix: "calendar")]
  # struct CalendarController < Athena::Routing::Controller
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

  # Parent struct for all controllers.
  abstract struct Controller
    # Exists the request with the given *status_code* and *body*.
    macro throw(status_code = 200, body = "")
      # Actual macro is declared on top level namespace
      # but documented here.
    end

    # :nodoc:
    class_property request : HTTP::Request? = nil

    # :nodoc:
    class_property response : HTTP::Server::Response? = nil

    # Returns the request object for the current request
    def self.get_request : HTTP::Request
      @@request.not_nil!
    end

    # Returns the response object for the current request
    def self.get_response : HTTP::Server::Response
      @@response.not_nil!
    end

    # Handles exceptions that could occur when using Athena.
    # Throws a 500 if the error does not match any handler.
    #
    # Method can be defined on child classes for controller specific error handling.
    def self.handle_exception(exception : Exception, action : String)
      case exception
      when Athena::Routing::Exceptions::AthenaException  then throw exception.code, exception.to_json
      when CrSerializer::Exceptions::ValidationException then throw 400, exception.to_json
      when ArgumentError                                 then throw 400, %({"code": 400, "message": "#{exception.message}"})
      when JSON::ParseException
        if msg = exception.message
          if parts = msg.match(/Expected (\w+) but was (\w+) .*[\r\n]*.+#(\w+)/)
            throw 400, %({"code": 400, "message": "Expected '#{parts[3]}' to be #{parts[1]} but got #{parts[2]}"})
          end
        end
      else
        # Otherwise throw a 500 if no other exception handlers are defined on any children
        throw 500, %({"code": 500, "message": "Internal Server Error"})
      end
    end
  end

  # :nodoc:
  abstract struct Action; end

  # :nodoc:
  abstract struct Param
    getter name : String

    def initialize(@name : String); end
  end

  # :nodoc:
  private abstract struct CallbackBase; end

  # :nodoc:
  private record RouteAction(A, R, C) < Action,
    # action that gets executed for the route.
    action : A,

    # Path that corresponds with this action.
    path : String,

    # Any callbacks declared for this action.
    callbacks : Callbacks,

    # Method of the action.
    method : String,

    # Serialization groups set on this action.
    groups : Array(String),

    # Array of parameters defined on this path/action.
    params : Array(Param) = [] of Param,

    # Renderer to use for the response of this action.
    renderer : R.class = R,

    # Controller this action belongs to.
    controller : C.class = C

  # :nodoc:
  private record Callbacks, on_response : Array(CallbackBase), on_request : Array(CallbackBase)

  # :nodoc:
  private record CallbackEvent(E) < CallbackBase, event : E, only_actions : Array(String), exclude_actions : Array(String)

  struct QueryParam(T) < Param
    getter pattern : Regex?

    def initialize(name : String, @pattern : Regex? = nil, @type : T.class = T)
      super name
    end
  end

  struct PathParam(T) < Param
    getter segment_index : Int32

    def initialize(name : String, @segment_index : Int32, @type : T.class = T)
      super name
    end
  end

  struct BodyParam(T) < Param
    def initialize(name : String, @type : T.class = T)
      super
    end
  end

  # # :nodoc:
  # private record QueryParam(T) < Param, name : String, pattern : Regex? = nil, type : T.class = T, in : String = "query"

  # # :nodoc:
  # private record PathParam(T) < Param, name : String, segment_index : Int32, type : T.class = T, in : String = "path"

  # # :nodoc:
  # private record BodyParam(T) < Param, name : String = "body", type : T.class = T, in : String = "body"

  # Starts the HTTP server with the given *port*, *binding*, *ssl*, and *handlers*.
  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server? | Bool? = nil, handlers : Array(HTTP::Handler) = [] of HTTP::Handler)
    config : Athena::Config::Config = Athena::Config::Config.from_yaml ECR.render "athena.yml"

    # If no handlers are passed to `.run`; build out the default handlers.
    # Otherwise just use user supplied handlers.
    if handlers.empty?
      handlers = [
        Athena::Routing::Handlers::CorsHandler.new,
        Athena::Routing::Handlers::ActionHandler.new,
      ] of HTTP::Handler
    end

    # Insert the RouteHandler automatically so the user does not have to deal with the config file.
    handlers.unshift Athena::Routing::Handlers::RouteHandler.new(config)

    # Validate the two required handlers are included.
    raise "First handler must be 'Athena::Routing::Handlers::RouteHandler'." unless handlers.first.is_a? Athena::Routing::Handlers::RouteHandler
    raise "Handlers must include 'Athena::Routing::Handlers::ActionHandler'." if handlers.none? &.is_a? Athena::Routing::Handlers::ActionHandler

    server : HTTP::Server = HTTP::Server.new handlers
    puts "Athena is leading the way on #{binding}:#{port}"

    unless server.each_address { |_| break true }
      {% if flag?(:without_openssl) %}
        server.bind_tcp(binding, port)
      {% else %}
        if ssl
          server.bind_tls(binding, port, ssl)
        else
          server.bind_tcp(binding, port)
        end
      {% end %}
    end

    # Signal::INT.trap do
    #   spawn { server.close }
    #   exit
    # end

    server.listen
  end
end

struct TestController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "/users/")]
  def self.test : String
    "sdf"
  end
end

Athena::Routing.run
