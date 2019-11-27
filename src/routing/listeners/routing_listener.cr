@[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
# Resolves a `ART::Route` from the current request
struct Athena::Routing::Listeners::Routing < AED::Listener
  include ADI::Service

  @route_resolver : ART::RouteResolver

  def initialize
    # Don't inject the route resolver since its a singleton
    @route_resolver = ART.route_resolver

    # TODO: Refactor logger to be service based
    # and optionally inject a logger instance
  end

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => 25,
    }
  end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    route = @route_resolver.resolve event.request

    event.request.route = route.payload.not_nil!
    event.request.path_params = route.params.not_nil!
  end
end
