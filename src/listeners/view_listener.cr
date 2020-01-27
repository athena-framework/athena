@[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
struct Athena::Routing::Listeners::View
  include AED::EventListenerInterface
  include ADI::Service

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::View => 25,
    }
  end

  def call(event : ART::Events::View, dispatcher : AED::EventDispatcherInterface) : Nil
    event.response = ART::Response.new event.view.data.to_json
  end
end
