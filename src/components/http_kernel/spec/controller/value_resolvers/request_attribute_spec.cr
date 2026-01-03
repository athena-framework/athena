require "../../spec_helper"

describe AHK::Controller::ValueResolvers::RequestAttribute do
  describe "#resolve" do
    it "that does not exist in the request attributes" do
      AHK::Controller::ValueResolvers::RequestAttribute.new.resolve(new_request, new_parameter).should be_nil
    end

    it "that exists in the request attributes" do
      request = new_request
      request.attributes.set "id", 1

      AHK::Controller::ValueResolvers::RequestAttribute.new.resolve(request, new_parameter).should eq 1
    end

    describe "that needs to be converted" do
      it String do
        parameter = AHK::Controller::ParameterMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "1"

        AHK::Controller::ValueResolvers::RequestAttribute.new.resolve(request, parameter).should eq 1
      end

      it Bool do
        parameter = AHK::Controller::ParameterMetadata(Bool).new "id"

        request = new_request
        request.attributes.set "id", "false"

        AHK::Controller::ValueResolvers::RequestAttribute.new.resolve(request, parameter).should be_false
      end

      it "that fails conversion" do
        parameter = AHK::Controller::ParameterMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "foo"

        expect_raises AHK::Exception::BadRequest, "Parameter 'id' with value 'foo' could not be converted into a valid 'Int32'." do
          AHK::Controller::ValueResolvers::RequestAttribute.new.resolve request, parameter
        end
      end
    end
  end
end
