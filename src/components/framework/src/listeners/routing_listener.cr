@[ADI::Register]
# Sets the related `ATH::Action` on the current request via an `ART::RequestMatcherInterface`.
struct Athena::Framework::Listeners::Routing
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ATH::Events::Request => 25,
    }
  end

  def initialize(@matcher : ART::RequestMatcherInterface); end

  # Assigns the resolved `ATH::Action` and path parameters to the request.
  #
  # The resolved route is dupped to avoid mutating the master copy in the singleton.
  def call(event : ATH::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    route = @matcher.match request

    Log.info &.emit "Matched route #{request.path}", uri: request.path, method: request.method, path_params: route.params, query_params: request.query_params.to_h

    request.action = route.payload.not_nil!.dup

    route.params.not_nil!.each do |key, value|
      event.request.attributes.set key, value
    end
  end
end
