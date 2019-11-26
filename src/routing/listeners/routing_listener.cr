@[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
struct Athena::Routing::Listeners::Routing < AED::Listener
  include ADI::Service

  @route_resolver : ART::RouteResolver

  def initialize
    # Don't inject the route resolver since its a singleton
    @route_resolver = ART.route_resolver
  end

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => 25,
    }
  end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    action = @route_resolver.resolve event.request

    pp "before"

    action.set_params [1, 99.0]

    pp action

    puts
    puts

    pp action.execute

    # pp event
  end
end
