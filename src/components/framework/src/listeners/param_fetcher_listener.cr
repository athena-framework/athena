@[ADI::Register]
struct Athena::Framework::Listeners::ParamFetcher
  include AED::EventListenerInterface

  def initialize(@param_fetcher : ATH::Params::ParamFetcherInterface); end

  @[AEDA::AsEventListener(priority: 5)]
  def on_action(event : ATH::Events::Action) : Nil
    request = event.request

    # Process each registered parameter, adding them to the request's attributes.
    @param_fetcher.each do |name, value|
      if request.attributes.has?(name) && !request.attributes.get(name).nil?
        raise ArgumentError.new %(Parameter '#{name}' conflicts with a path parameter for route '#{request.attributes.get "_route"}'.)
      end

      request.attributes.set name, value
    end
  end
end
