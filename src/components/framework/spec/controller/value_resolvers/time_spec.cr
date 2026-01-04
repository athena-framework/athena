require "../../spec_helper"

private def resolver(
  annotations = ADI::AnnotationConfigurations.new,
) forall T
  ATHR::Time.new(
    MockAnnotationResolver.new(
      action_parameter_annotations: annotations,
      expected_parameter_name: "foo"
    )
  )
end

describe ATHR::Time do
  describe "#resolve" do
    it "some other type parameter" do
      resolver.resolve(new_request, AHK::Controller::ParameterMetadata(Int32).new "foo").should be_nil
      resolver.resolve(new_request, AHK::Controller::ParameterMetadata(Int32?).new "foo").should be_nil
      resolver.resolve(new_request, AHK::Controller::ParameterMetadata(Bool | Float64).new "foo").should be_nil
    end

    it "type is nilable and the value is nil" do
      parameter = AHK::Controller::ParameterMetadata(String?).new "foo"
      request = new_request
      request.attributes.set "foo", nil

      resolver.resolve(request, parameter).should be_nil
    end

    it "is not a Time parameter" do
      parameter = AHK::Controller::ParameterMetadata(String).new "foo"
      request = new_request

      resolver.resolve(request, parameter).should be_nil
    end

    it "type is nilable" do
      parameter = AHK::Controller::ParameterMetadata(::Time?).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      resolver.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "type a union of another type" do
      parameter = AHK::Controller::ParameterMetadata(Int32 | ::Time).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      resolver.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "is missing from request attributes" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new "foo"
      request = new_request

      resolver.resolve(request, parameter).should be_nil
    end

    it "is is a ::Time instance already" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new "foo"
      request = new_request
      request.attributes.set "foo", now = Time.utc

      resolver.resolve(request, parameter).should eq now
    end

    it "is not a string" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new "foo"
      request = new_request
      request.attributes.set "foo", 100

      resolver.resolve(request, parameter).should be_nil
    end

    it "parses RFC 3339 by default" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new "foo"
      request = new_request
      request.attributes.set "foo", "2020-04-07T12:34:56Z"

      resolver.resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "allows specifying a format" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new("foo")

      request = new_request
      request.attributes.set "foo", "2020--04//07  12:34:56"

      resolver(
        annotations: ADI::AnnotationConfigurations.new({
          ATHA::MapTime => [
            ATHA::MapTimeConfiguration.new(format: "%Y--%m//%d  %T"),
          ] of ADI::AnnotationConfigurations::ConfigurationBase,
        } of ADI::AnnotationConfigurations::Classes => Array(ADI::AnnotationConfigurations::ConfigurationBase)),
      )
        .resolve(request, parameter).should eq Time.utc 2020, 4, 7, 12, 34, 56
    end

    it "allows specifying a location to parse the format in" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new("foo")

      request = new_request
      request.attributes.set "foo", "2020--04//07  12:34:56"

      resolver(
        annotations: ADI::AnnotationConfigurations.new({
          ATHA::MapTime => [
            ATHA::MapTimeConfiguration.new(format: "%Y--%m//%d  %T", location: Time::Location.fixed(9001)),
          ] of ADI::AnnotationConfigurations::ConfigurationBase,
        } of ADI::AnnotationConfigurations::Classes => Array(ADI::AnnotationConfigurations::ConfigurationBase)),
      )
        .resolve(request, parameter).should eq Time.local 2020, 4, 7, 12, 34, 56, location: Time::Location.fixed(9001)
    end

    it "raises an AHK::Exception::BadRequest if a time could not be parsed from the string" do
      parameter = AHK::Controller::ParameterMetadata(::Time).new "foo"
      request = new_request
      request.attributes.set "foo", "foo"

      expect_raises AHK::Exception::BadRequest, "Invalid date(time) for parameter 'foo'." do
        resolver.resolve request, parameter
      end
    end
  end
end
