require "http/server"
require "json"

require "amber_router"
require "event-dispatcher"
require "athena-config"
require "athena-di"

require "./annotations"
require "./argument_resolver"
require "./request_store"
require "./route_resolver"
require "./route_handler"
require "./types"

require "./exceptions/*"
require "./config/*"
require "./converters/*"
require "./parameters/*"
require "./listeners/*"
require "./events/*"

require "./ext/event_dispatcher"
require "./ext/request"
require "./ext/listener"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

module Athena::Routing
  # :nodoc:
  @@server : HTTP::Server?

  protected class_getter route_resolver : ART::RouteResolver { ART::RouteResolver.new }

  # Parent class for all controllers.
  #
  # Can be inherited from to add utility methods useful in all controllers.
  abstract class Controller
    {% begin %}
      {% for method in ["GET", "POST", "PUT", "PATCH", "DELETE"] %}
        # Helper DSL macro for creating `{{method.id}}` actions.
        #
        # ### Optional Named Arguments
        # - `args` - The arguments that this action should take.  Defaults to no arguments.
        # - `return_type` - The return type to set for the action.  Defaults to `String` if not provided.
        # - `constraints` - Any constraints that should be applied to the route.
        #
        # ### Example
        #
        # ```
        # class ExampleController < ART::Controller
        #  {{method.downcase.id}} "user/:id", args: {id : Int32}, return_type: String, constraints: {"id" => /\d+/} do
        #    "Got user #{id}"
        #  end
        # end
        # ```
        private macro {{method.downcase.id}}(path, *args, **named_args, &)
          @[ART::{{method.capitalize.id}}(path: \{{path}}, constraints: \{{named_args[:constraints]}})]
          def {{method.downcase.id}}_\{{path.gsub(/\W/, "_").id}}(\{{*args}}) : \{{named_args[:return_type] || String}}
            \{{yield}}
          end
        end
      {% end %}
    {% end %}
  end

  abstract class Action; end

  class Route(ActionType, ReturnType, *ArgTypes) < Action
    # The `ART::Controller` that handles `self` by default.
    getter controller : ART::Controller.class

    # A `Proc(Proc)` representing the controller action that handles the `HTTP::Request` on `self`.
    #
    # The outer proc instantiates the controller instance and creates a proc with the action.
    # This ensures each request gets its own instance of the controller to prevent leaking state.
    getter action : ActionType

    # The arguments that will be passed the `#action`.
    getter arguments : ArgTypes? = nil

    getter argument_names

    # The parameters that need to be parsed from the request
    #
    # Includes route, body, and query params
    getter parameters : Array(ART::Parameters::Param)

    # The return type of the action.
    getter return_type : ReturnType.class = ReturnType

    getter converters : Array(ART::Converters::ParamConverterConfiguration)

    def initialize(
      @controller : ART::Controller.class,
      @argument_names : Array(String),
      @action : ActionType,
      @parameters : Array(ART::Parameters::Param) = [] of ART::Parameters::Param,
      @converters : Array(ART::Converters::ParamConverterConfiguration) = [] of ART::Converters::ParamConverterConfiguration
    )
    end

    # Allows changing the value of a specific *argument*.
    #
    # Most useful for use with a custom `ART::Events::ActionArguments` listener.
    #
    # NOTE: *value* must be of the correct type, otherwise a runtime `TypeCastError` will be raised.
    def set(argument : String, value) : Nil
      {% if ArgTypes.size > 0 %}
        index = @argument_names.index argument

        @arguments = ArgTypes.from @arguments.not_nil!.map_with_index { |arg, idx| idx == index ? value : arg }.to_a
      {% end %}
    end

    # Get the value of a specific *argument*.
    def get(argument : String)
      @arguments[@argument_names.index(argument).not_nil!]
    end

    # :nodoc:
    #
    # Used internally to set the initial `arguments` values from `Athena::Routing::ArgumentResolver#resolve`.
    def set_arguments(args : Array) : Nil
      {% if ArgTypes.size > 0 %}
        @arguments = ArgTypes.from args
      {% end %}
    end

    # Executes `#action` with the given `#arguments`.
    def execute : ReturnType
      {% if ArgTypes.size > 0 %}
        @action.call.call *@arguments.not_nil!
      {% else %}
        @action.call.call
      {% end %}
    end
  end

  # Stops the server.
  def self.stop : Nil
    if server = @@server
      server.close unless server.closed?
    else
      raise "Server not set"
    end
  end

  # Starts the HTTP server with the given *port*, *host*, *ssl*, *reuse_port*.
  def self.run(port : Int32 = 3000, host : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server | Bool | Nil = nil, reuse_port : Bool = false)
    # Define the server
    @@server = HTTP::Server.new do |ctx|
      # Instantiate a new instance of the container so that
      # the container objects do not bleed between requests
      Fiber.current.container = Athena::DI::ServiceContainer.new

      # Pass the request context to the route handler
      ART::RouteHandler.new.handle ctx

      nil
    end

    unless @@server.not_nil!.each_address { break true }
      {% if flag?(:without_openssl) %}
        @@server.not_nil!.bind_tcp(host, port, reuse_port: reuse_port)
      {% else %}
        if ssl
          @@server.not_nil!.bind_tls(host, port, ssl, reuse_port: reuse_port)
        else
          @@server.not_nil!.bind_tcp(host, port, reuse_port: reuse_port)
        end
      {% end %}
    end

    @@server.not_nil!.listen
  end
end
