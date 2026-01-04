require "../../spec_helper"

describe AHK::Controller::ValueResolvers::Request do
  describe "#resolve" do
    it TestController do
      parameter = AHK::Controller::ParameterMetadata(TestController).new "foo"

      AHK::Controller::ValueResolvers::Request.new.resolve(new_request, parameter).should be_nil
    end

    it "with a valid value" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Request).new "foo"
      request = new_request

      AHK::Controller::ValueResolvers::Request.new.resolve(request, parameter).should be request
    end
  end
end
