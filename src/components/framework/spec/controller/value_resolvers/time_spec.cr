require "../../spec_helper"

private class TimeParent
  def with_format(@[ATHR::Time::Format(format: "%Y--%m//%d  %T")] time : Time); end

  def with_time_and_location(@[ATHR::Time::Format(format: "%Y--%m//%d  %T", location: Time::Location.fixed(9001))] time : Time); end
end

describe ATHR::Time do
  describe "#resolve" do
    it "some other type parameter" do
      ATHR::Time.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32, TestController, 0, 0).new "foo").should be_nil
      ATHR::Time.new.resolve(new_request, ATH::Controller::ParameterMetadata(Int32?, TestController, 0, 0).new "foo").should be_nil
      ATHR::Time.new.resolve(new_request, ATH::Controller::ParameterMetadata(Bool | Float64, TestController, 0, 0).new "foo").should be_nil
    end

    it "type is nilable and the value is nil" do
      parameter = ATH::Controller::ParameterMetadata(String?, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", nil

      ATHR::Time.new.resolve(request, parameter).should be_nil
    end

    it "is not a Time parameter" do
      parameter = ATH::Controller::ParameterMetadata(String, TestController, 0, 0).new "foo"
      request = new_request

      ATHR::Time.new.resolve(request, parameter).should be_nil
    end

    it "type is nilable" do
      parameter = ATH::Controller::ParameterMetadata(::Time?, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      ATHR::Time.new.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "type a union of another type" do
      parameter = ATH::Controller::ParameterMetadata(Int32 | ::Time, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      ATHR::Time.new.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "is missing from request attributes" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TestController, 0, 0).new "foo"
      request = new_request

      ATHR::Time.new.resolve(request, parameter).should be_nil
    end

    it "is is a ::Time instance already" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", now = Time.utc

      ATHR::Time.new.resolve(request, parameter).should eq now
    end

    it "is not a string" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", 100

      ATHR::Time.new.resolve(request, parameter).should be_nil
    end

    it "parses RFC 3339 by default" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      ATHR::Time.new.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "allows specifying a format" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TimeParent, 0, 0).new("foo")

      request = new_request
      request.attributes.set "foo", "2020--04//07  12:34:56"

      ATHR::Time.new.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "allows specifying a location to parse the format in" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TimeParent, 1, 0).new("foo")

      request = new_request
      request.attributes.set "foo", "2020--04//07  12:34:56"

      ATHR::Time.new.resolve(request, parameter).should eq Time.local 2020, 4, 7, 12, 34, 56, location: Time::Location.fixed(9001)
    end

    it "raises an ATH::Exceptions::BadRequest if a time could not be parsed from the string" do
      parameter = ATH::Controller::ParameterMetadata(::Time, TestController, 0, 0).new "foo"
      request = new_request
      request.attributes.set "foo", "foo"

      expect_raises ATH::Exceptions::BadRequest, "Invalid date(time) for parameter 'foo'." do
        ATHR::Time.new.resolve request, parameter
      end
    end
  end
end
