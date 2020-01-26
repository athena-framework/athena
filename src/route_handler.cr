# The entry-point into `Athena::Routing`.
#
# Emits events that handle a given request.
struct Athena::Routing::RouteHandler
  include ADI::Injectable

  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_store : ART::RequestStore,
    @argument_resolver : ART::ArgumentResolverInterface
  )
  end

  def handle(context : HTTP::Server::Context) : Nil
    handle_raw context
  rescue ex : ::Exception
    event = ART::Events::Exception.new context.request, ex
    @event_dispatcher.dispatch event

    exception = event.exception

    finish_request(context) do |ctx|
      if exception.is_a? ART::Exceptions::HTTPException
        # Add headers from the exception
        ctx.response.headers.merge! exception.headers
        ctx.response.status = exception.status
      else
        ctx.response.status = :internal_server_error
      end

      exception.to_json ctx.response
    end

    # Raise the exception again to help with debugging if in the development ENV and response is a 500.
    # In the future make this part of an ExceptionListener or something
    raise exception if Athena.environment == "development" && context.response.status.internal_server_error?
  end

  private def handle_raw(context : HTTP::Server::Context) : Nil
    # Set the current request in the RequestStore
    @request_store.request = context.request

    # Emit the request event
    request_event = ART::Events::Request.new context
    @event_dispatcher.dispatch request_event

    # Return the event early if one was set
    return finish_request context if request_event.request_finished?

    # Resolve and set the arguments from the request
    context.request.route.set_arguments @argument_resolver.resolve context

    # Possibly add another event here to allow modification of the resolved arguments?

    # Call the action and get the response
    response = context.request.route.execute

    # TODO: Add a view layer
    # unless response.is_a? ART::Response
    #   view_event = context.request.route.create_view_event response, context
    #   @event_dispatcher.dispatch view_event
    #
    #   if view_event.has_response?
    #     response = view_event.response
    #   else
    #     raise "Controller x did not return an ART::Response"
    #   end
    # end

    finish_request(context) do |ctx|
      # Return 204 if route's return type is `nil`
      if ctx.request.route.return_type == Nil
        ctx.response.status = :no_content
      else
        # Otherwise write the response
        response.to_json ctx.response
      end
    end
  end

  private def finish_request(context : HTTP::Server::Context) : Nil
    finish_request(context) { }
  end

  # Emits the Response event, writes the final response body, closes the response, then emits the Terminate event.
  private def finish_request(context : HTTP::Server::Context, & : HTTP::Server::Context -> Nil) : Nil
    # Emit the response event
    @event_dispatcher.dispatch ART::Events::Response.new context

    context.response.content_type = "application/json"

    # Yield the context to write the response
    yield context

    # Emit the finish request event
    @event_dispatcher.dispatch ART::Events::FinishRequest.new context

    # Reset the request store
    @request_store.reset

    # Close the response
    context.response.close

    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new context
  end
end
