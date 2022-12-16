require "../../spec_helper"

describe ATHR::UUID do
  describe "#resolve" do
    it "does not exist in request attributes" do
      parameter = ATH::Controller::ParameterMetadata(UUID).new "foo"
      ATHR::UUID.new.resolve(new_request, parameter).should be_nil
    end

    it "some other type" do
      ATHR::UUID.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32).new "foo").should be_nil
      ATHR::UUID.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32?).new "foo").should be_nil
      ATHR::UUID.new.resolve(new_request, ATH::Controller::ParameterMetadata(Bool | String).new "foo").should be_nil
    end
    it "attribute exists but is not a string" do
      parameter = ATH::Controller::ParameterMetadata(UUID).new "foo"
      request = new_request
      request.attributes.set "foo", 100

      ATHR::UUID.new.resolve(request, parameter).should be_nil
    end

    it "attribute exists but is nil with a nullable parameter" do
      parameter = ATH::Controller::ParameterMetadata(UUID?).new "foo"
      request = new_request
      request.attributes.set "foo", nil

      ATHR::UUID.new.resolve(request, parameter).should be_nil
    end

    it "with a valid value" do
      parameter = ATH::Controller::ParameterMetadata(UUID).new "foo"

      uuid = UUID.random

      request = new_request
      request.attributes.set "foo", uuid.to_s

      ATHR::UUID.new.resolve(request, parameter).should eq uuid
    end

    it "type a union of another type" do
      parameter = ATH::Controller::ParameterMetadata(UUID | Int32).new "foo"
      request = new_request

      uuid = UUID.random

      request.attributes.set "foo", uuid.to_s

      ATHR::UUID.new.resolve(request, parameter).should eq uuid
    end

    it "with a valid nilable value" do
      parameter = ATH::Controller::ParameterMetadata(UUID?).new "foo"

      uuid = UUID.random

      request = new_request
      request.attributes.set "foo", uuid.to_s

      ATHR::UUID.new.resolve(request, parameter).should eq uuid
    end

    it "with an invalid value" do
      parameter = ATH::Controller::ParameterMetadata(UUID).new "foo"

      request = new_request
      request.attributes.set "foo", "foo"

      expect_raises ATH::Exceptions::BadRequest, "Parameter 'foo' with value 'foo' is not a valid 'UUID'." do
        ATHR::UUID.new.resolve request, parameter
      end
    end
  end
end
