@[ADI::Register]
# Sets the related `ART::Action` on the current request using `ART::RouteResolver`.
struct Athena::Routing::Listeners::ParamListener
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Action => 5,
    }
  end

  def initialize(@param_fetcher : ART::Params::ParamFetcherInterface); end

  # Assigns the resolved `ART::Action` and path parameters to the request.
  #
  # The resolved route is dupped to avoid mutating the master copy in the singleton.
  def call(event : ART::Events::Action, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    @param_fetcher.each do |name, value|
      if request.attributes.has?(name) && !request.attributes.get(name).nil?
        raise ArgumentError.new "Parameter '#{name}' conflicts with a path parameter for route '#{request.action.action_name}'."
      end

      # p! name, value

      request.attributes.set name, value
    end
  end
end
