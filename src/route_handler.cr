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
    return_response handle_raw(context.request), context
  rescue ex : ::Exception
    event = ART::Events::Exception.new context.request, ex
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

    return_response finish_response(response, context.request), context
  end

  private def return_response(response : ART::Response, context : HTTP::Server::Context) : Nil
    # Apply the `ART::Response` to the actual `HTTP::Server::Response` object
    IO.copy response.io.rewind, context.response
    context.response.headers.merge! response.headers
    context.response.status = response.status

    # Close the response
    context.response.close

    # Emit the terminate event
    @event_dispatcher.dispatch ART::Events::Terminate.new context.request, response
  end

  private def handle_raw(request : HTTP::Request) : ART::Response
    # Set the current request in the RequestStore
    @request_store.request = request

    # Emit the request event
    request_event = ART::Events::Request.new request
    @event_dispatcher.dispatch request_event

    # Return the event early if the request event handled the request
    if response = request_event.response
      return finish_response response, request
    end

    # Resolve the arguments for this route from the request
    arguments = @argument_resolver.resolve request, request.route

    # Possibly add another event here to allow modification of the resolved arguments?

    # Call the action and get the response
    response = request.route.execute arguments

    unless response.is_a? ART::Response
      view_event = ART::Events::View.new request, ART::View.new(response)
      @event_dispatcher.dispatch view_event

      unless response = view_event.response
        raise "#{request.route.controller}##{request.route.action_name} must return an `ART::Response` but it returned '#{response}'."
      end
    end

    finish_response response, request
  end

  private def finish_response(response : ART::Response, request : HTTP::Request) : ART::Response
    # Emit the response event
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
