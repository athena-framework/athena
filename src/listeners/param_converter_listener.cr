@[ADI::Register(_param_converters: "!athena.param_converter")]
# Applies any `ATH::ParamConverter` defined on a given `ATH::Action`.
#
# Injects all `ATH::ParamConverter` tagged with `ATH::ParamConverter::TAG`.
struct Athena::Framework::Listeners::ParamConverter
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ATH::Events::Action => -250,
    }
  end

  @param_converters = Hash(ATH::ParamConverter.class, ATH::ParamConverter).new

  def initialize(param_converters : Array(ATH::ParamConverter))
    param_converters.each do |converter|
      @param_converters[converter.class] = converter
    end
  end

  def call(event : ATH::Events::Action, dispatcher : AED::EventDispatcherInterface) : Nil
    event.action.apply_param_converters @param_converters, event.request
  end
end
