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
    def call_next(context : HTTP::Server::Context)
      if next_handler = @next
        next_handler.call(context)
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
  #
  # ## Example
  # ```
  # @[Athena::Routing::ParamConverter(param: "user", type: User, converter: Exists)]
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

  # Raised when a an object could not be found in the `Athena::Routing::Converters::Exists` converter.
  class NotFoundException < Exception
    # Returns a 404 not found JSON error.
    #
    # ```
    # {
    #   "code":    404,
    #   "message": "An item with the provided ID could not be found.",
    # }
    # ```
    def to_json : String
      {
        code:    404,
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
  abstract class ClassController; end

  # Parent class for all `Struct` based controllers.
  abstract struct StructController; end

  # :nodoc:
  private abstract struct Action; end

  # :nodoc:
  private abstract struct CallbackBase; end

  # :nodoc:
  private abstract struct Param; end

  # :nodoc:
  private record RouteAction(A, R) < Action, action : A, path : String, callbacks : Callbacks, method : String, groups : Array(String), query_params : Array(Param), renderer : R.class = R

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
