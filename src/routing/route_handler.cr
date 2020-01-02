# The entrypoint into Athena::Routing.
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
  end

  private def handle_raw(ctx : HTTP::Server::Context) : Nil
    # Set the current request in the RequestStore
    @request_store.request = ctx.request

    # Emit the request event
    request_event = ART::Events::Request.new ctx
    @event_dispatcher.dispatch request_event

    # Return the event early if one was set.
    return finish_request ctx if request_event.request_finished?

    # Resolve and set the arguments from the request
    ctx.request.route.set_arguments @argument_resolver.resolve ctx

    # Emit the route action arguments event
    @event_dispatcher.dispatch ART::Events::ActionArguments.new ctx.request

    # # Call the action and get the response
    response = ctx.request.route.execute

    # Return 204 if route's return type is nil
    if ctx.request.route.return_type == Nil
      ctx.response.status = :no_content
    else
      # Otherwise write the response
      response.to_json ctx.response
    end

    ctx.response.content_type = "application/json"

    finish_request ctx

    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new ctx.request, ctx.response
  end

  private def finish_request(ctx : HTTP::Server::Context) : Nil
    # Emit the response event
    @event_dispatcher.dispatch ART::Events::Response.new ctx

    @request_store.reset

    # Close the response
    ctx.response.close
  end
end
