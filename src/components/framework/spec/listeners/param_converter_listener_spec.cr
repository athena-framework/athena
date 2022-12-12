require "../spec_helper"

class MockParamConverter < ATH::ParamConverter
  def apply(request : ATH::Request, configuration : Configuration) : Nil
    request.attributes.set "argument", true, Bool
  end
end

describe ATH::Listeners::ParamConverter do
  it "applies param converters related to the given route" do
    action = create_action param_converters: {MockParamConverter::Configuration(Nil).new("argument", MockParamConverter)} do
      "FOO"
    end

    event = ATH::Events::Action.new new_request, action

    event.request.attributes.has?("argument").should be_false

    ATH::Listeners::ParamConverter.new([MockParamConverter.new]).on_action event

    event.request.attributes.has?("argument").should be_true
  end
end
