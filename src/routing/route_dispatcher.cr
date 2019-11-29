# The entrypoint into Athena::Routing.
#
# Emits events that handle a given request.
struct Athena::Routing::RouteDispatcher < AED::Listener
  include ADI::Injectable

  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_store : ART::RequestStore
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

      exception.to_json ctx.response
    else
      response.status = :internal_server_error
      exception.to_json ctx.response

      response.close

      raise exception
    end
  end

  private def handle_raw(ctx : HTTP::Server::Context) : Nil
    # Set the current request in the RequestStore
    @request_store.request = ctx.request

    # Emit the request event
    @event_dispatcher.dispatch ART::Events::Request.new ctx.request

    # Resolve and set the arguments from the request
    ctx.request.route.set_arguments ctx.request.route.parameters.map &.parse(ctx.request)

    # Emit the route action arguments event
    @event_dispatcher.dispatch ART::Events::ActionArguments.new ctx.request

    # # Call the action and get the response
    response = ctx.request.route.execute

    # Emit the response event
    @event_dispatcher.dispatch ART::Events::Response.new ctx.response

    # Write the response
    response.to_json ctx.response

    # Close the response
    ctx.response.close

    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new ctx.request, ctx.response
  end
end
