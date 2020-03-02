@[ADI::Register("@athena_routing_error_renderer", tags: ["athena.event_dispatcher.listener"])]
# Handles an exception by converting it into an `ART::Response` via an `ART::ErrorRendererInterface`.
struct Athena::Routing::Listeners::Error
  include AED::EventListenerInterface
  include ADI::Service

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Exception => -50,
    }
  end

  def initialize(@error_renderer : ART::ErrorRendererInterface)
    # TODO: Refactor logger to be service based
    # and optionally inject a logger instance
  end

  def call(event : ART::Events::Exception, dispatcher : AED::EventDispatcherInterface) : Nil
    event.response = @error_renderer.render event.exception
  end
end
