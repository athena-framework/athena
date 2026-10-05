require "./spec_helper"

describe AHK::Action do
  describe "#execute" do
    it "with an argument resolver" do
      action = AHK::Action.new(
        Proc(Tuple(Int32, Int32), Int32).new { |(a, b)| a - b },
        {AHK::Controller::ParameterMetadata(Int32).new("a"), AHK::Controller::ParameterMetadata(Int32).new("b")},
        Int32,
      )

      request = new_request action: action
      request.attributes.set "a", 10
      request.attributes.set "b", 7

      argument_resolver = AHK::Controller::ArgumentResolver.new [AHK::Controller::ValueResolvers::RequestAttribute.new] of AHK::Controller::ValueResolvers::Interface

      action.execute(request, argument_resolver).should eq 3
    end
  end
end
