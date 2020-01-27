@[ADI::Register("@error_renderer", tags: ["athena.event_dispatcher.listener"])]
struct Athena::Routing::Listeners::Error
  include AED::EventListenerInterface
  include ADI::Service

  def initialize(@error_renderer : ART::ErrorRendererInterface)
    # TODO: Refactor logger to be service based
    # and optionally inject a logger instance
  end

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Exception => -50,
    }
  end

  def call(event : ART::Events::Exception, dispatcher : AED::EventDispatcherInterface) : Nil
    event.response = @error_renderer.render event.exception
  end
end
