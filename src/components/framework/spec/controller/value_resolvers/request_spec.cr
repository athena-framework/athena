require "../../spec_helper"

describe ATHR::Request do
  describe "#resolve" do
    it TestController do
      parameter = ATH::Controller::ParameterMetadata(TestController).new "foo"

      ATHR::Request.new.resolve(new_request, parameter).should be_nil
    end

    it "with a valid value" do
      parameter = ATH::Controller::ParameterMetadata(ATH::Request).new "foo"
      request = new_request

      ATHR::Request.new.resolve(request, parameter).should be request
    end
  end
end
