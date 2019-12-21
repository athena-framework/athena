@[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
# Sets the related `ART::Route` on the current request.
struct Athena::Routing::Listeners::Routing < AED::Listener
  include ADI::Service

  def initialize
    # TODO: Refactor logger to be service based
    # and optionally inject a logger instance
  end

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => 25,
    }
  end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    pp "resolving #{event.request.path}"
    # The route_resolver must be called here for controller DI to work.
    # Other option would be to new up a route resolver for every request. :shrug:
    route = ART.route_resolver.resolve event.request

    event.request.route = route.payload.not_nil!.dup
    event.request.path_params = route.params.not_nil!
  end
end
