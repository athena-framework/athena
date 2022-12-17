require "../spec_helper"

private struct TrueResolver
  include ATHR::Interface

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    17
  end
end

describe ATH::Controller::ArgumentResolver do
  describe "#get_arguments" do
    describe "when a value was able to be resolved" do
      it "should return an array of values" do
        route = new_action arguments: {new_parameter}

        ATH::Controller::ArgumentResolver.new([TrueResolver.new] of ATHR::Interface).get_arguments(new_request, route).should eq [17]
      end
    end

    describe "when a value was not able to be resolved" do
      it "should raise a runtime error" do
        route = new_action arguments: {new_parameter}

        expect_raises(RuntimeError, "Controller 'TestController#test' requires that you provide a value for the 'id' parameter. Either the parameter is nilable and no nil value has been provided, or no default value has been provided.") do
          ATH::Controller::ArgumentResolver.new([] of ATHR::Interface).get_arguments(new_request, route)
        end
      end
    end
  end
end
