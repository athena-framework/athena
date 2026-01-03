require "../../spec_helper"

describe AHK::Controller::ValueResolvers::DefaultValue do
  describe "#resolve" do
    it "does not have a default nor is nilable" do
      parameter = AHK::Controller::ParameterMetadata(String).new "foo", false, nil

      AHK::Controller::ValueResolvers::DefaultValue.new.resolve(new_request, parameter).should be_nil
    end

    it "does not have a default but is nilable" do
      parameter = AHK::Controller::ParameterMetadata(String?).new "foo", false, nil

      AHK::Controller::ValueResolvers::DefaultValue.new.resolve(new_request, parameter).should be_nil
    end

    it "has a nil default value and is nilable" do
      parameter = AHK::Controller::ParameterMetadata(String?).new "foo", true, nil

      AHK::Controller::ValueResolvers::DefaultValue.new.resolve(new_request, parameter).should be_nil
    end

    it "with a default value" do
      parameter = AHK::Controller::ParameterMetadata(String).new "foo", true, "bar"

      AHK::Controller::ValueResolvers::DefaultValue.new.resolve(new_request, parameter).should eq "bar"
    end
  end
end
