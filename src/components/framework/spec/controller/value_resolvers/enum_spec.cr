require "../../spec_helper"

enum TestEnum
  A
  B
  C
end

describe ATHR::Enum do
  describe "#resolve" do
    it "some other type" do
      ATHR::Enum.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32).new "enum").should be_nil
      ATHR::Enum.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32?).new "enum").should be_nil
      ATHR::Enum.new.resolve(new_request, ATH::Controller::ParameterMetadata(Bool | String).new "enum").should be_nil
    end

    it "is not a string" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"
      request = new_request
      request.attributes.set "enum", 1

      ATHR::Enum.new.resolve(request, parameter).should be_nil
    end

    it "that does not exist in request attributes" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"

      ATHR::Enum.new.resolve(new_request, parameter).should be_nil
    end

    it "that is nilable and not exist in request attributes" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum?).new "enum"

      ATHR::Enum.new.resolve(new_request, parameter).should be_nil
    end

    it "that is a union of another type" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum | String).new "enum"
      request = new_request
      request.attributes.set "enum", "1"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::B
    end

    it "the enum member is nilable" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum?).new "enum"
      request = new_request
      request.attributes.set "enum", "1"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::B
    end

    it "with a numeric based value" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "2"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::C
    end

    it "with a numeric based value with whitespace" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "2"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::C
    end

    it "with a string based value" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "B"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::B
    end

    it "with a string based nilable value" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum?).new "enum"

      request = new_request
      request.attributes.set "enum", "B"

      ATHR::Enum.new.resolve(request, parameter).should eq TestEnum::B
    end

    it "with an unknown member value" do
      parameter = ATH::Controller::ParameterMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "  4  "

      expect_raises ATH::Exceptions::BadRequest, "Parameter 'enum' of enum type 'TestEnum' has no valid member for '  4  '." do
        ATHR::Enum.new.resolve request, parameter
      end
    end
  end
end
