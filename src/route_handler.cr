# The entry-point into `Athena::Routing`.
#
# Emits events that handle a given request.
struct Athena::Routing::RouteHandler
  include ADI::Injectable

  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_store : ART::RequestStore,
    @argument_resolver : ART::ArgumentResolver
  )
  end

  def handle(ctx : HTTP::Server::Context) : Nil
    handle_raw ctx
  rescue ex : ::Exception
    event = ART::Events::Exception.new ctx.request, ex
    @event_dispatcher.dispatch event

    exception = event.exception
    response = ctx.response

    # Add content-type header
    response.content_type = "application/json"

    if exception.is_a? ART::Exceptions::HTTPException
      # Add headers from the exception
      response.headers.merge! exception.headers
      response.status = exception.status
    else
      response.status = :internal_server_error
    end

    exception.to_json ctx.response

    response.close

    # Raise the exception again to help with debugging if in the development ENV and response is a 500.
    # In the future make this part of an ExceptionListener or something
    raise exception if Athena.environment == "development" && response.status.internal_server_error?
  end

  private def handle_raw(ctx : HTTP::Server::Context) : Nil
    # Set the current request in the RequestStore
    @request_store.request = ctx.request

    # Emit the request event
    request_event = ART::Events::Request.new ctx
    @event_dispatcher.dispatch request_event

    # Return the event early if one was set
    return finish_request ctx if request_event.request_finished?

    # Resolve and set the arguments from the request
    ctx.request.route.set_arguments @argument_resolver.resolve ctx

    # Possibly add another event here to allow modification of the resolved arguments?

    # Call the action and get the response
    response = ctx.request.route.execute

    # TODO: Add a view layer
    # unless response.is_a? ART::Response
    #   view_event = route.create_view_event response, ctx
    #   @event_dispatcher.dispatch view_event
    #
    #   if view_event.has_response?
    #     response = view_event.response
    #   else
    #     raise "Controller x did not return an ART::Response"
    #   end
    # end

    ctx.response.content_type = "application/json"

    # Return 204 if route's return type is `nil`
    if ctx.request.route.return_type == Nil
      ctx.response.status = :no_content
      finish_request(ctx)
    else
      # Otherwise write the response
      finish_request(ctx) { response.to_json ctx.response }
    end
  end

  private def finish_request(ctx : HTTP::Server::Context) : Nil
    finish_request(ctx) {}
  end

  private def finish_request(ctx : HTTP::Server::Context, &block : HTTP::Server::Context -> _) : Nil
    # Emit the response event
    @event_dispatcher.dispatch ART::Events::Response.new ctx

    yield ctx
    # Reset the request store
    @request_store.reset

    # Close the response
    ctx.response.close

    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new ctx
  end
end
