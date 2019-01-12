require "http/server"
require "amber_router"
require "json"
require "CrSerializer"

require "./routing/route_handler"
require "./routing/converters"
require "./routing/macros"
require "./routing/renderers"
require "./common/types"

module Athena
  # :nodoc:
  module HTTP::Handler
    def call_next(context : HTTP::Server::Context)
      if next_handler = @next
        next_handler.call(context)
      end
    end
  end

  # Defines a GET endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Get(path: "/users")]
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Post(path: "/users")]
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Put(path: "/users")]
  # ```
  annotation Put; end

  # Defines a DELETE endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Delete(path: "/users/:id")]
  # ```
  annotation Delete; end

  # Controls how params are converted.
  # ## Fields
  # * param : `String` - The param that should go through the conversion.
  # * type : `T` - The type the param should be converted to.
  # * converter : `Athena::Converters` - What converter to use for the conversion.  Can be `Converters::RequestBody`, `Converters::Exists`, `Converters::FormData`, or a custom defined converter.
  #
  # ## Example
  # ```
  # @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  # ```
  annotation ParamConverter; end

  # Defines a callback that should be called at a specific point in the request's life-cycle.
  # ## Fields
  # * event : `CallbackEvents` - The event that the callback should be executed at.
  # * only : `Array(String)` - Run the callback only for the provided actions.
  # * exclude : `Array(String)` - Run the callback for all actions except those provided.
  #
  # ## Example
  # ```
  # @[Athena::Callback(event: Athena::CallbackEvents::OnResponse, only: ["users"])]
  # ```
  annotation Callback; end

  # Defines how the return value of an endpoint is displayed.
  # ## Fields
  # * groups : `Array(String)` - The serialization groups to apply to this endpoint.
  # See the [CrSerializer Docs](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md) for more info.
  # * renderer : `Athena::Renderers` - What renderer to use for the return value/object.  Default is `Athena::Renderers::JSONRenderer`
  #
  # ## Example
  # ```
  # @[Athena::View(groups: ["admin", "default"])]
  # ```
  annotation View; end

  # Raised when a an object could not be found in the `Athena::Converters::Exists` converter.
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
  private record RouteAction(A, R) < Action, action : A, path : String, callbacks : Callbacks, method : String, groups : Array(String), renderer : R.class = R

  # :nodoc:
  private record Callbacks, on_response : Array(CallbackBase), on_request : Array(CallbackBase)

  # :nodoc:
  private record CallbackEvent(E) < CallbackBase, event : E, only_actions : Array(String), exclude_actions : Array(String)

  # Starts the HTTP server with the given *port*, *binding*, *ssl*, and *handlers*.
  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server? | Bool? = nil, handlers : Array(HTTP::Handler) = [Athena::RouteHandler.new])
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
