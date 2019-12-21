@[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
struct Athena::Routing::Listeners::Cors < AED::Listener
  include ADI::Service

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => 250,
    }
  end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    # Return early if not a CORS request.
    # TODO: optimize this by also checking of origin matches the request's host.
    return unless request.headers.has_key? "origin"

    # If the request is a preflight, return the proper response.
    if request.method == "OPTIONS" && request.headers.has_key? "access-control-request-method"
      set_preflight_response event

      event.set_response
      return
    end

    event.response.print "foo"

    # Stop propagation so future listeners don't mutate the response further.
    event.set_response
  end

  # Configures the given *response* for CORS preflight
  private def set_preflight_response(response : HTTP::Server::Response) : Nil
  end
end
