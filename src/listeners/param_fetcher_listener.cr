@[ADI::Register]
struct Athena::Routing::Listeners::ParamListener
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Action => 5,
    }
  end

  def initialize(@param_fetcher : ART::Params::ParamFetcherInterface); end

  def call(event : ART::Events::Action, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    # Process each registered parameter, adding them to the request's attributes.
    @param_fetcher.each do |name, value|
      if request.attributes.has?(name) && !request.attributes.get(name).nil?
        raise ArgumentError.new "Parameter '#{name}' conflicts with a path parameter for route '#{request.action.name}'."
      end

      request.attributes.set name, value
    end
  end
end
