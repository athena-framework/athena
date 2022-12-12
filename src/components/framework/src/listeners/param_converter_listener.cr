@[ADI::Register(_param_converters: "!athena.param_converter")]
# Applies any `ATH::ParamConverter` defined on a given `ATH::Action`.
#
# Injects all `ATH::ParamConverter` tagged with `ATH::ParamConverter::TAG`.
struct Athena::Framework::Listeners::ParamConverter
  include AED::EventListenerInterface

  @param_converters = Hash(ATH::ParamConverter.class, ATH::ParamConverter).new

  def initialize(param_converters : Array(ATH::ParamConverter))
    param_converters.each do |converter|
      @param_converters[converter.class] = converter
    end
  end

  @[AEDA::AsEventListener(priority: -250)]
  def on_action(event : ATH::Events::Action) : Nil
    event.action.apply_param_converters @param_converters, event.request
  end
end
