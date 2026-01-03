# The entry-point into `Athena::HTTPKernel`.
#
# Emits events that handle a given request and returns the resulting [AHTTP::Response](/HTTP/Response).
struct Athena::HTTPKernel::HTTPKernel
  def initialize(
    @event_dispatcher : AED::EventDispatcherInterface,
    @request_store : AHTTP::RequestStore,
    @argument_resolver : AHK::Controller::ArgumentResolverInterface,
    @action_resolver : AHK::ActionResolverInterface,
  )
  end

  def handle(request : ::HTTP::Request) : AHTTP::Response
    self.handle AHTTP::Request.new request
  end

  def handle(request : AHTTP::Request) : AHTTP::Response
    handle_raw request
  rescue ex : ::Exception
    event = AHK::Events::Exception.new request, ex
    @event_dispatcher.dispatch event

    exception = event.exception

    unless response = event.response
      finish_request

      raise exception
    end

    if exception.is_a? AHK::Exception::HTTPException
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
  def terminate(request : AHTTP::Request, response : AHTTP::Response) : Nil
    @event_dispatcher.dispatch AHK::Events::Terminate.new request, response
  end

  private def handle_raw(request : AHTTP::Request) : AHTTP::Response
    # Set the current request in the RequestStore.
    @request_store.request = request

    # Emit the request event.
    request_event = AHK::Events::Request.new request
    @event_dispatcher.dispatch request_event

    # Return the event early if the request event handled the request.
    if response = request_event.response
      return finish_response response, request
    end

    unless action = @action_resolver.resolve request
      raise AHK::Exception::NotFound.new "Unable to find the action for path '#{request.path}'."
    end

    # Emit the action event.
    @event_dispatcher.dispatch AHK::Events::Action.new request, action

    # Resolve the arguments for this action from the request.
    arguments = @argument_resolver.get_arguments request, action

    # Call the action and get the response.
    response = action.execute arguments

    unless response.is_a? AHTTP::Response
      view_event = AHK::Events::View.new request, response
      @event_dispatcher.dispatch view_event

      unless response = view_event.response
        raise %('#{request.attributes.get? "_controller" || "AHK::Action"}' must return an `AHTTP::Response` but it returned '#{response}'.)
      end
    end

    finish_response response, request
  end

  private def finish_response(response : AHTTP::Response, request : AHTTP::Request) : AHTTP::Response
    # Emit the response event.
    event = AHK::Events::Response.new request, response

    @event_dispatcher.dispatch event

    self.finish_request

    event.response
  end

  private def finish_request : Nil
    # Reset the request store.
    @request_store.reset
  end
end
