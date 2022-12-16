require "../../spec_helper"

describe ATHR::RequestAttribute do
  describe "#resolve" do
    it "that does not exist in the request attributes" do
      ATHR::RequestAttribute.new.resolve(new_request, new_parameter).should be_nil
    end

    it "that exists in the request attributes" do
      request = new_request
      request.attributes.set "id", 1

      ATHR::RequestAttribute.new.resolve(request, new_parameter).should eq 1
    end

    describe "that needs to be converted" do
      it String do
        parameter = ATH::Controller::ParameterMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "1"

        ATHR::RequestAttribute.new.resolve(request, parameter).should eq 1
      end

      it Bool do
        parameter = ATH::Controller::ParameterMetadata(Bool).new "id"

        request = new_request
        request.attributes.set "id", "false"

        ATHR::RequestAttribute.new.resolve(request, parameter).should be_false
      end

      it "that fails conversion" do
        parameter = ATH::Controller::ParameterMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "foo"

        expect_raises ATH::Exceptions::BadRequest, "Parameter 'id' with value 'foo' could not be converted into a valid 'Int32'." do
          ATHR::RequestAttribute.new.resolve request, parameter
        end
      end
    end
  end
end
