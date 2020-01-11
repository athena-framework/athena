require "http/server"
require "json"

require "amber_router"
require "athena-config"
require "athena-di"
require "athena-event_dispatcher"

require "./annotations"
require "./argument_resolver"
require "./controller"
require "./param_converter_configuration"
require "./param_converter_interface"
require "./request_store"
require "./route_handler"
require "./route_resolver"

require "./config/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./parameters/*"

require "./ext/configuration_resolver"
require "./ext/conversion_types"
require "./ext/event_dispatcher"
require "./ext/listener"
require "./ext/request"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# The Routing component provides an event based framework for converting a request into a response
# and includes various abstractions/useful types to make that process easier.
#
# Athena is an event based framework; meaning it emits `ART::Events` that are acted upon to handle the request.
# Athena also utilizes `Athena::DI` to provide a service container layer.  The service container layer
# allows a project to share/inject useful objects between various types, such as a custom `AED::Listener`, `ART::Controller`, or `ART::Converters::ParamConverter`.
# See the corresponding types for more information.
#
# * See `ART::Controller` for documentation on defining controllers/route actions.
# * See `ART::Config` for documentation on configuration options available for the Routing component.
# * See `ART::Events` for documentation on the events that can be listened on during the request's life-cycle.
# * See `ART::Converters` for documentation on using param converters.
# * See `ART::Exceptions` for documentation on exception handling.
module Athena::Routing
  # :nodoc:
  @@server : HTTP::Server?

  protected class_getter route_resolver : ART::RouteResolver { ART::RouteResolver.new }

  # The events that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  #
  # See each specific event for more detailed information.
  module Athena::Routing::Events; end

  # Parent type of a route just used for typing.
  #
  # See `ART::Route`.
  abstract class Action; end

  class Route(Controller, ActionType, ReturnType, *ArgTypes) < Action
    # The `ART::Controller` that handles `self` by default.
    getter controller : ART::Controller.class = Controller

    # A `Proc(Proc)` representing the controller action that handles the `HTTP::Request` on `self`.
    #
    # The outer proc instantiates the controller instance and creates a proc with the action.
    # This ensures each request gets its own instance of the controller to prevent leaking state.
    getter action : ActionType

    # The arguments that will be passed the `#action`.
    getter arguments : ArgTypes? = nil

    # The parameters that need to be parsed from the request
    #
    # Includes route, body, and query params
    getter parameters : Array(ART::Parameters::Param)

    # The return type of the action.
    getter return_type : ReturnType.class = ReturnType

    getter converters : Array(ART::ParamConverterConfigurationBase)

    def initialize(
      @action : ActionType,
      @parameters : Array(ART::Parameters::Param) = [] of ART::Parameters::Param,
      @converters : Array(ART::ParamConverterConfigurationBase) = [] of ART::ParamConverterConfigurationBase
    )
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
