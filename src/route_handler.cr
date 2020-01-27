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

  def handle(request : HTTP::Request) : ART::Response
    handle_raw request
  rescue ex : ::Exception
    event = ART::Events::Exception.new request, ex
    @event_dispatcher.dispatch event

    exception = event.exception

    unless response = event.response
      finish_request

      raise exception
    end

    if exception.is_a? ART::Exceptions::HTTPException
      response.status = exception.status
      response.headers.merge! exception.headers
    end

    finish_response response, request
  end

  private def handle_raw(request : HTTP::Request) : ART::Response
    # Set the current request in the RequestStore
    @request_store.request = request

    # Emit the request event
    request_event = ART::Events::Request.new request
    @event_dispatcher.dispatch request_event

    # Return the event early if the request event handled the reuest
    if response = request_event.response
      return finish_response response, request
    end

    # Resolve and set the arguments from the request
    request.route.set_arguments @argument_resolver.resolve request

    # Possibly add another event here to allow modification of the resolved arguments?

    # Call the action and get the response
    response = request.route.execute

    # TODO: Add a view layer
    unless response.is_a? ART::Response
      view_event = ART::Events::View.new request, ART::View.new(response)
      @event_dispatcher.dispatch view_event

      unless response = view_event.response
        raise "Controller x did not return an ART::Response"
      end
    end

    finish_response response, request
  end

  def terminate(request : HTTP::Request, response : ART::Response) : Nil
    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new request, response
  end

  private def finish_response(response : ART::Response, request : HTTP::Request) : ART::Response
    # # Emit the response event
    event = ART::Events::Response.new request, response

    @event_dispatcher.dispatch event

    finish_request

    event.response
  end

  private def finish_request : Nil
    # Reset the request store
    @request_store.reset
  end
end
