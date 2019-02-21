require "http/server"
require "amber_router"
require "json"
require "CrSerializer"

require "./common/types"

require "./routing/route_handler"
require "./routing/converters"
require "./routing/macros"
require "./routing/renderers"
require "./common/types"

# Athena module containing elements for:
# * Defining routes.
# * Defining life-cycle callbacks.
# * Manage response serialization.
# * Handle param conversion.
module Athena::Routing
  # :nodoc:
  module HTTP::Handler
    def call_next(ctx : HTTP::Server::Context)
      if next_handler = @next
        next_handler.call(ctx)
      end
    end
  end

  # Enable static file handling.  Disabled by default.
  class_property static_file_handler : HTTP::StaticFileHandler? = nil

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
  # * [id_type] : `P` - The type the id should be resolved to before calling `T.find`.  Only required for `Converters::Exists`.
  #
  # ## Example
  # ```
  # @[Athena::Routing::ParamConverter(param: "user", id_type: Int32, type: User, converter: Exists)]
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
  # @[Athena::Routing::Controller(prefix: "calendar")]
  # class CalendarController < Athena::Routing::ClassController
  #   # The rotue of this action would be `GET /calendar/events`
  #   @[Athena::Routing::Get(path: "events")]
  #   def self.events : String
  #     "events"
  #   end
  # end
  # ```
  annotation Controller; end

  # A generic exception that can be thrown with  to render consistent exception responses with the given code and messsage.
  class AthenaException < Exception
    getter code : Int32

    def initialize(@code : Int32, @message); end

    # Serializes the exception into a JSON object with the given *code* and *message*.
    #
    # ```
    # {
    #   "code":    409,
    #   "message": "A user with this email already exists.",
    # }
    # ```
    def to_json : String
      {
        code:    @code,
        message: @message,
      }.to_json
    end
  end

  # Events available during the request's life-cycle.
  enum CallbackEvents
    # Executes before the route's action has been executed.
    OnRequest

    # Executes after the route's action has been executed.
    OnResponse
  end

  # Parent class for all `Class` based controllers.
  abstract class ClassController
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
  end

  # Parent class for all `Struct` based controllers.
  abstract struct StructController
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
  end

  # :nodoc:
  private abstract struct Action; end

  # :nodoc:
  private abstract struct CallbackBase; end

  # :nodoc:
  private abstract struct Param; end

  # :nodoc:
  private record RouteAction(A, R, B, C) < Action, action : A, path : String, callbacks : Callbacks, method : String, groups : Array(String), query_params : Array(Param), body_type : B.class = B, renderer : R.class = R, controller : C.class = C

  # :nodoc:
  private record Callbacks, on_response : Array(CallbackBase), on_request : Array(CallbackBase)

  # :nodoc:
  private record CallbackEvent(E) < CallbackBase, event : E, only_actions : Array(String), exclude_actions : Array(String)

  # :nodoc:
  private record QueryParam(T) < Param, name : String, pattern : Regex? = nil, type : T.class = T

  # Starts the HTTP server with the given *port*, *binding*, *ssl*, and *handlers*.
  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server? | Bool? = nil, handlers : Array(HTTP::Handler) = [Athena::Routing::RouteHandler.new] of HTTP::Handler)
    if sfh = self.static_file_handler
      handlers.unshift sfh
    end

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

    server.listen
  end
end
