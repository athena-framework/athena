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
    if event.request.route.return_type == Nil
      data = ""
      status = HTTP::Status::NO_CONTENT
    else
      data = event.view.data.to_json
      status = HTTP::Status::OK
    end

    event.response = ART::Response.new data, status, HTTP::Headers{"content-type" => "application/json"}
  end
end
