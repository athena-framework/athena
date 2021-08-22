require "../spec_helper"

class MockParamConverter < ART::ParamConverterInterface
  def apply(request : ART::Request, configuration : Configuration) : Nil
    request.attributes.set "argument", true, Bool
  end
end

describe ART::Listeners::ParamConverter do
  it "applies param converters related to the given route" do
    action = create_action param_converters: {MockParamConverter::Configuration(Nil).new("argument", MockParamConverter)} do
      "FOO"
    end

    event = ART::Events::Action.new new_request, action

    event.request.attributes.has?("argument").should be_false

    ART::Listeners::ParamConverter.new([MockParamConverter.new]).call event, AED::Spec::TracableEventDispatcher.new

    event.request.attributes.has?("argument").should be_true
  end
end
