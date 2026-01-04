require "../spec_helper"

private struct TrueResolver
  include AHK::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata)
    17
  end
end

describe AHK::Controller::ArgumentResolver do
  describe "#get_arguments" do
    describe "when a value was able to be resolved" do
      it "should return an array of values" do
        route = new_action arguments: {new_parameter}

        AHK::Controller::ArgumentResolver.new([TrueResolver.new] of AHK::Controller::ValueResolvers::Interface).get_arguments(new_request, route).should eq [17]
      end
    end

    describe "when a value was not able to be resolved" do
      it "should raise a runtime error" do
        route = new_action arguments: {new_parameter}

        expect_raises(RuntimeError, "AHK::Action requires that you provide a value for the 'id' parameter. Either the parameter is nilable and no nil value has been provided, or no default value has been provided.") do
          AHK::Controller::ArgumentResolver.new([] of AHK::Controller::ValueResolvers::Interface).get_arguments(new_request, route)
        end
      end
    end
  end
end
