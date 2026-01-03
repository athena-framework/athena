require "log"
require "json"
require "semantic_version"

require "athena-event_dispatcher"
require "athena-http"

require "./action"
require "./action_resolver_interface"
require "./action_resolver"
require "./error_renderer_interface"
require "./error_renderer"
require "./http_kernel"

require "./controller/**"

require "./events/request_aware"
require "./events/settable_response"
require "./events/*"

require "./exception/http_exception"
require "./exception/*"

require "./listeners/error"

macro finished
  {% if @top_level.has_constant?("ART") %}
    require "./listeners/routing"
  {% end %}
end

# Convenience alias to make referencing `Athena::HTTPKernel` types easier.
alias AHK = Athena::HTTPKernel

module Athena::HTTPKernel
  VERSION = "0.1.0"
  Log     = ::Log.for "athena.http_kernel"

  # This type includes all of the built-in resolvers that the HTTPKernel uses to try and resolve an argument for a particular controller action parameter.
  #
  # Custom resolvers may also be defined.
  # See `AHK::Controller::ValueResolvers::Interface` for more information.
  module Controller::ValueResolvers; end

  # The [ACTR::EventDispatcher::Event](/Contracts/EventDispatcher/Event/) that are emitted via `Athena::EventDispatcher` to handle a request during its life-cycle.
  # Custom events can also be defined and dispatched within a controller, listener, or some other service.
  module Events; end

  # Exception handling in Athena is similar to exception handling in any Crystal program, with the addition of a new unique exception type, `AHK::Exception::HTTPException`.
  #
  # When an exception is raised, Athena emits the `AHK::Events::Exception` event to allow an opportunity for it to be handled.
  # If the exception goes unhandled, i.e. no listener set an [AHTTP::Response](/HTTP/Response) on the event, then the request is finished and the exception is re-raised.
  # Otherwise, that response is returned, setting the status and merging the headers on the exceptions if it is an `AHK::Exception::HTTPException`.
  # See `AHK::Listeners::Error` and `AHK::ErrorRendererInterface` for more information on how exceptions are handled by default.
  #
  # To provide the best response to the client, non `AHK::Exception::HTTPException` should be rescued and converted into a corresponding `AHK::Exception::HTTPException`.
  # Custom HTTP errors can also be defined by inheriting from `AHK::Exception::HTTPException` or a child type.
  # A use case for this could be allowing for additional data/context to be included within the exception that ultimately could be used in a `AHK::Events::Exception` listener.
  module Exception; end
end
