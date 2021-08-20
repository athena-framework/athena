require "../spec_helper"

private struct MockParamConverter < ART::ParamConverterInterface
  def apply(request : ART::Request, configuration : Configuration) : Nil
    request.attributes.set "argument", true, Bool
  end
end

describe ART::Listeners::ParamConverter do
  it "applies param converters related to the given route" do
    converters = [MockParamConverter::Configuration(Nil).new("argument", MockParamConverter)] of ART::ParamConverterInterface::ConfigurationInterface
    event = ART::Events::Action.new new_request, new_action param_converters: converters

    event.request.attributes.has?("argument").should be_false

    ART::Listeners::ParamConverter.new([MockParamConverter.new]).call event, AED::Spec::TracableEventDispatcher.new

    event.request.attributes.has?("argument").should be_true
  end
end
