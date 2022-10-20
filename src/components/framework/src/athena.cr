require "ecr"
require "http/server"
require "json"

require "athena-config"
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
require "./config/*"
require "./events/*"
require "./exceptions/*"
require "./listeners/*"
require "./parameters/*"
require "./params/*"
require "./view/*"

require "./ext/conversion_types"
require "./ext/console"
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
  module Athena::Framework::Events; end

  # Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `ATH::Exceptions::HTTPException`.
  #
  # When an exception is raised, Athena emits the `ATH::Events::Exception` event to allow an opportunity for it to be handled. If the exception goes unhandled, i.e. no listener set
  # an `ATH::Response` on the event, then the request is finished and the exception is reraised. Otherwise, that response is returned, setting the status and merging the headers on the exceptions
  # if it is an `ATH::Exceptions::HTTPException`. See `ATH::Listeners::Error` and `ATH::ErrorRendererInterface` for more information on how exceptions are handled by default.
  #
  # To provide the best response to the client, non `ATH::Exceptions::HTTPException` should be rescued and converted into a corresponding `ATH::Exceptions::HTTPException`.
  # Custom HTTP errors can also be defined by inheriting from `ATH::Exceptions::HTTPException` or a child type. A use case for this could be allowing for additional data/context to be included
  # within the exception that ultimately could be used in a `ATH::Events::Exception` listener.
  module Athena::Framework::Exceptions; end

  # The `AED::EventListenerInterface` that act upon `ATH::Events` to handle a request. Custom listeners can also be defined, see `AED::EventListenerInterface`.
  #
  # See each listener and the [external documentation](/components/event_dispatcher/) for more information.
  module Athena::Framework::Listeners
    # The tag name for Athena event listeners.
    TAG = "athena.event_dispatcher.listener"

    # Apply `TAG` to all `AED::EventListenerInterface` instances automatically.
    ADI.auto_configure AED::EventListenerInterface, {tags: [ATH::Listeners::TAG]}
  end

  # Namespace for types related to controller action arguments.
  #
  # See `ATH::Arguments::ArgumentMetadata`.
  module Athena::Framework::Arguments; end

  # The default `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`s that will handle resolving controller action arguments from a request (or other source).
  # Custom argument value resolvers can also be defined, see `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`.
  #
  # NOTE: In order for `Athena::Framework` to pick up your custom value resolvers, be sure to `ADI::Register` it as a service, and tag it as `ATH::Arguments::Resolvers::TAG`.
  # A `priority` field can also be optionally included in the annotation, the higher the value the sooner in the array it'll be when injected.
  #
  # See each resolver for more detailed information.
  module Athena::Framework::Arguments::Resolvers
    # The tag name for `ATH::Arguments::Resolvers::ArgumentValueResolverInterface`s.
    TAG = "athena.argument_value_resolver"
  end

  # Namespace for types related to request parameter processing.
  #
  # See `ATHA::QueryParam` and `ATHA::RequestParam`.
  module Athena::Framework::Params; end

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

module MakeControllerServicesPublicPass
  include Athena::DependencyInjection::PreArgumentsCompilerPass

  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, metadata|
            if metadata[:service] <= ATH::Controller
              metadata[:public] = true
            end
          end
        %}
      {% end %}
    end
  end
end

module RegisterCommandsPass
  include Athena::DependencyInjection::PostArgumentsCompilerPass

  macro included
    macro finished
      {% verbatim do %}
        {%
          command_map = {} of Nil => Nil
          command_refs = {} of Nil => Nil

          TAG_HASH["athena.console.command"].each do |service_id|
            metadata = SERVICE_HASH[service_id]

            # TODO: Figure out way to make this not public
            metadata[:public] = true

            tags = metadata[:tags].select &.[:name].==("athena.console.command")

            # If `command` is set on the first tag, use that as aliases
            # otherwise resolve from the `AsCommand` annotation

            if !tags.empty? && (ann = metadata[:service].annotation ACONA::AsCommand)
              aliases = if tag_command = tags[0][:command]
                          tag_command
                        else
                          ann[0] || ann[:name]
                        end

              aliases = (aliases || "").split "|"
              command_name = aliases[0]
              aliases = aliases[1..]

              if is_hidden = "" == command_name
                command_name = aliases[0]

                unless aliases.empty?
                  aliases = aliases[1..]
                end
              end

              if command_name == nil
                # TODO: Do something here?
                # Make public alias for the command?
              end

              description = tags[0][:description]

              tags = tags[1..]

              command_map[command_name] = metadata[:service]
              command_refs[metadata[:service]] = service_id

              aliases.each do |a|
                command_map[a] = metadata[:service]
              end

              # TODO: Add method calls to handle additional aliases, hidden commands, and description

              if !description
                description = ann[:description]
              end
            end
          end

          DefineLocators::LOCATORS << {
            name: "ContainerCommandLoaderContainer",
            map:  command_refs,
          }

          SERVICE_HASH["athena_console_command_loader_container"] = {
            public:    false,
            service:   "ContainerCommandLoaderContainer",
            ivar_type: "ContainerCommandLoaderContainer",
            tags:      [] of Nil,
            generics:  [] of Nil,
            arguments: [
              {value: "self".id},
            ],
          }

          SERVICE_HASH["athena_console_command_loader"] = {
            public:    true,
            service:   ContainerCommandLoader,
            ivar_type: ContainerCommandLoader,
            tags:      [] of Nil,
            generics:  [] of Nil,
            arguments: [
              {value: command_map},
              {value: "athena_console_command_loader_container".id},
            ],
          }

          USED_SERVICE_IDS << "athena_console_command_loader_container".id
          USED_SERVICE_IDS << "athena_console_command_loader".id
        %}
      {% end %}
    end
  end
end

module DefineLocators
  include ADI::PostArgumentsCompilerPass

  LOCATORS = [] of Nil

  macro included
    macro finished
      {% verbatim do %}
        {% for locator in LOCATORS %}
          # :nodoc:
          struct ::{{locator[:name].id}}
            def initialize(@container : ADI::ServiceContainer); end

            {% for service_type, service_id in locator[:map] %}
              def get(service : {{service_type}}.class) : {{service_type}}
                @container.{{service_id.id}}
              end
            {% end %}
            
            def get(service)
              {% begin %}
                case service
                {% for service_type, service_id in locator[:map] %}
                  when {{service_type}} then @container.{{service_id.id}}
                {% end %}
                else
                  raise "BUG: Couldn't find correct service."
                end
              {% end %}
            end
          end
        {% end %}
      {% end %}
    end
  end
end

struct ContainerCommandLoader
  include Athena::Console::Loader::Interface

  @command_map : Hash(String, ACON::Command.class)

  def initialize(
    @command_map : Hash(String, ACON::Command.class),
    @loader : ContainerCommandLoaderContainer
  ); end

  # :inherit:
  def get(name : String) : ACON::Command
    if !self.has? name
      raise ACON::Exceptions::CommandNotFound.new "Command '#{name}' does not exist."
    end

    @loader.get @command_map[name]
  end

  # :inherit:
  def has?(name : String) : Bool
    @command_map.has_key? name
  end

  # :inherit:
  def names : Array(String)
    @command_map.keys
  end
end

# # Register an example service that provides a name string.
# @[ADI::Register]
# class NameProvider
#   def name : String
#     "World"
#   end
# end

# # Register another service that depends on the previous service and provides a value.
# @[ADI::Register]
# class ValueProvider
#   def initialize(@name_provider : NameProvider); end

#   def value : String
#     "Hello " + @name_provider.name
#   end
# end

# # Register a service controller that depends upon the ValueProvider.
# @[ADI::Register]
# class ExampleController < ATH::Controller
#   def initialize(@value_provider : ValueProvider); end

#   @[ARTA::Get("/")]
#   def get_value : String
#     @value_provider.value
#   end
# end

@[ADI::Register]
@[ACONA::AsCommand("test")]
class TestCommand < ACON::Command
  def initialize
    pp "New #{{{@type}}}"
    super
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # Implement all the business logic here.

    output.puts "foo"

    # Indicates the command executed successfully.
    ACON::Command::Status::SUCCESS
  end
end

@[ADI::Register]
@[ACONA::AsCommand("blah")]
class BlahCommand < ACON::Command
  def initialize
    pp "New #{{{@type}}}"
    super
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # Implement all the business logic here.

    output.puts "bar"

    # Indicates the command executed successfully.
    ACON::Command::Status::SUCCESS
  end
end

loader = ADI.container.athena_console_command_loader

# pp loader.get("blah")

application = ACON::Application.new "Athena", ATH::VERSION
application.command_loader = ADI.container.athena_console_command_loader

application.run

# ATH.run
