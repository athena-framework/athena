@[ADI::Register(_param_converters: "!athena.param_converter", tags: [ART::Listeners::TAG])]
struct Athena::Routing::Listeners::ParamConverter
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Request => -250,
    }
  end

  @param_converters : Hash(ART::ParamConverterInterface.class, ART::ParamConverterInterface) = Hash(ART::ParamConverterInterface.class, ART::ParamConverterInterface).new

  def initialize(param_converters : Array(ART::ParamConverterInterface))
    param_converters.each do |converter|
      @param_converters[converter.class] = converter
    end
  end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    event.request.route.param_converters.each do |configuration|
      @param_converters[configuration.converter].apply event.request, configuration
    end
  end
end
