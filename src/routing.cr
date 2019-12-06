require "http/server"
require "json"

require "amber_router"
require "event-dispatcher"

require "./common/types"

require "./di"

require "./routing/request_store"
require "./routing/route_resolver"
require "./routing/route_dispatcher"

require "./routing/exceptions/*"
require "./routing/converters/*"
require "./routing/handlers/*"
require "./routing/parameters/*"
require "./routing/renderers/*"
require "./routing/listeners/*"
require "./routing/events/*"

require "./routing/ext/listener"
require "./routing/ext/event_dispatcher"
require "./routing/ext/request"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Athena module containing elements for:
# * Defining routes.
# * Defining life-cycle callbacks.
# * Manage response serialization.
# * Handle param conversion.
module Athena::Routing
  # :nodoc:
  @@server : HTTP::Server?

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
  annotation QueryParam; end

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
  # class CalendarController < Athena::Routing::Controller
  #   # The route of this action would be `GET /calendar/events`
  #   @[Athena::Routing::Get(path: "events")]
  #   def self.events : String
  #     "events"
  #   end
  # end
  # ```
  annotation ControllerOptions; end

  # Parent struct for all controllers.
  abstract struct Controller
  end

  abstract class Action; end

  class Route(ActionType, *ArgTypes) < Action
    # The `ART::Controller` that handles `self` by default.
    getter controller : ART::Controller.class

    # A `Proc` representing the controller action that handles `HTTP::Request` on `self`.
    getter action : ActionType

    # The arguments that will be passed the `#action`.
    getter arguments : ArgTypes? = nil

    # The parameters that need to be parsed from the request
    #
    # Includes route, body, and query params
    getter parameters : Array(ART::Parameters::Param)

    def initialize(@controller : ART::Controller.class, @action : ActionType, @parameters : Array(ART::Parameters::Param))
    end

    def set_arguments(args : Array)
      {% if ArgTypes.size > 0 %}
        @arguments = ArgTypes.from args
      {% end %}
    end

    # Executes `#action` with the given `#arguments`.
    def execute
      {% if ArgTypes.size > 0 %}
        if args = @arguments
          @action.call *args
        end
      {% else %}
        @action.call
      {% end %}
    end
  end

  # Stops the server.
  def self.stop
    if server = @@server
      server.close unless server.closed?
    else
      raise "Server not set"
    end
  end

  protected class_getter route_resolver : ART::RouteResolver = ART::RouteResolver.new

  # Starts the HTTP server with the given *port*, *binding*, *ssl*, *reuse_port*.
  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server | Bool | Nil = nil, reuse_port : Bool = false)
    # Define the server
    @@server = HTTP::Server.new do |ctx|
      # Instantiate a new instance of the container so that
      # the container objects do not bleed between requests
      Fiber.current.container = Athena::DI::ServiceContainer.new

      # Pass the request context to the route dispatcher
      ART::RouteDispatcher.new.handle ctx

      nil
    end

    unless @@server.not_nil!.each_address { break true }
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
  end
end
