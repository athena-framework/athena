# The entrypoint into Athena::Routing.
#
# Emits events that handle a given request.
struct Athena::Routing::RouteDispatcher < AED::Listener
  include ADI::Injectable

  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_stack : ART::RequestStack
  )
  end

  def handle(ctx : HTTP::Server::Context) : Nil
    handle_raw ctx.request
  rescue ex : ::Exception
    @event_dispatcher.dispatch ART::Events::Exception.new ctx.request, ex

    raise ex
  end

  private def handle_raw(request : HTTP::Request)
    @event_dispatcher.dispatch ART::Events::Request.new request
  end
end
