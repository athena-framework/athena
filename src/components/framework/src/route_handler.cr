# The entry-point into `Athena::Framework`.
#
# Emits events that handle a given request and returns the resulting `ATH::Response`.
@[ADI::Register(name: "athena_route_handler", public: true)]
struct Athena::Framework::RouteHandler
  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_store : ATH::RequestStore,
    @argument_resolver : ATH::Controller::ArgumentResolverInterface,
    @controller_resolver : ATH::ControllerResolverInterface
  )
  end

  def handle(request : HTTP::Request) : ATH::Response
    self.handle ATH::Request.new request
  end

  def handle(request : ATH::Request) : ATH::Response
    handle_raw request
  rescue ex : ::Exception
    event = ATH::Events::Exception.new request, ex
    @event_dispatcher.dispatch event

    exception = event.exception

    unless response = event.response
      finish_request

      raise exception
    end

    if exception.is_a? ATH::Exception::HTTPException
      response.status = exception.status
      response.headers.merge! exception.headers
    end

    begin
      finish_response response, request
    rescue
      response
    end
  end

  # Terminates a request/response lifecycle.
  #
  # Should be called after sending the response to the client.
  def terminate(request : ATH::Request, response : ATH::Response) : Nil
    @event_dispatcher.dispatch ATH::Events::Terminate.new request, response
  end

  private def handle_raw(request : ATH::Request) : ATH::Response
    # Set the current request in the RequestStore.
    @request_store.request = request

    # Emit the request event.
    request_event = ATH::Events::Request.new request
    @event_dispatcher.dispatch request_event

    # Return the event early if the request event handled the request.
    if response = request_event.response
      return finish_response response, request
    end

    # TODO: Possibly add another event here to allow modification of the resolved "controller"?
    request.action = @controller_resolver.resolve request

    # Emit the action event.
    @event_dispatcher.dispatch ATH::Events::Action.new request, request.action

    # Resolve the arguments for this action from the request.
    arguments = @argument_resolver.get_arguments request, request.action

    # TODO: Possibly add another event here to allow modification of the resolved arguments?

    # Call the action and get the response.
    response = request.action.execute arguments

    unless response.is_a? ATH::Response
      view_event = ATH::Events::View.new request, response
      @event_dispatcher.dispatch view_event

      unless response = view_event.response
        raise %('#{request.attributes.get "_controller"}' must return an `ATH::Response` but it returned '#{response}'.)
      end
    end

    finish_response response, request
  end

  private def finish_response(response : ATH::Response, request : ATH::Request) : ATH::Response
    # Emit the response event.
    event = ATH::Events::Response.new request, response

    @event_dispatcher.dispatch event

    self.finish_request

    event.response
  end

  private def finish_request : Nil
    # Reset the request store.
    @request_store.reset
  end
end
