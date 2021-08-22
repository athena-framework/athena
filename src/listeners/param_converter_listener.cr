@[ADI::Register(_param_converters: "!athena.param_converter")]
# Applies any `ART::ParamConverter` defined on a given `ART::Action`.
#
# Injects all `ART::ParamConverter` tagged with `ART::ParamConverter::TAG`.
struct Athena::Routing::Listeners::ParamConverter
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::Action => -250,
    }
  end

  @param_converters : Hash(ART::ParamConverter.class, ART::ParamConverter) = Hash(ART::ParamConverter.class, ART::ParamConverter).new

  def initialize(param_converters : Array(ART::ParamConverter))
    param_converters.each do |converter|
      @param_converters[converter.class] = converter
    end
  end

  def call(event : ART::Events::Action, dispatcher : AED::EventDispatcherInterface) : Nil
    event.action.apply_param_converters @param_converters, event.request
  end
end
