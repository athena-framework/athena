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
    @event_dispatcher.dispatch ART::Events::Exception.new ctx.request, ex

    raise ex
  end

  private def handle_raw(ctx : HTTP::Server::Context) : Nil
    # Set the current request in the RequestStore
    @request_store.request = ctx.request

    # Emit the on_request event
    @event_dispatcher.dispatch ART::Events::Request.new ctx.request

    # Resole the arguments from the request
    ctx.request.route.set_arguments ctx.request.route.parameters.map &.parse(ctx.request)

    # # Call the action and get the response
    response = ctx.request.route.execute

    # Write the response
    ctx.response.print response.to_json
  end
end
