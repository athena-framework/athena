require "./spec_helper"

describe ART::TimeConverter do
  it "noops if the argument isn't within the request attributes" do
    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter
    request = new_request
    request.attributes.has?("time").should be_false

    ART::TimeConverter.new.apply request, configuration

    request.attributes.has?("time").should be_false
  end

  it "retuurns the value as is if it's already a Time instance" do
    now = Time.utc

    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter
    request = new_request
    request.attributes.set "time", now

    ART::TimeConverter.new.apply request, configuration

    request.attributes.get("time").should eq now
  end

  it "parses RFC 3339 by default" do
    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter
    request = new_request
    request.attributes.set "time", "2020-04-07T12:34:56Z", String

    ART::TimeConverter.new.apply request, configuration

    request.attributes.get("time").should eq Time.utc 2020, 4, 7, 12, 34, 56
  end

  it "allows specifying a format" do
    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter, format: "%Y--%m//%d  %T"
    request = new_request
    request.attributes.set "time", "2020--04//07  12:34:56", String

    ART::TimeConverter.new.apply request, configuration

    request.attributes.get("time").should eq Time.utc 2020, 4, 7, 12, 34, 56
  end

  it "allows specifying a location to parse the format in" do
    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter, format: "%Y--%m//%d  %T", location: Time::Location.load("Europe/Berlin")
    request = new_request
    request.attributes.set "time", "2020--04//07  12:34:56", String

    ART::TimeConverter.new.apply request, configuration

    request.attributes.get("time").should eq Time.local 2020, 4, 7, 12, 34, 56, location: Time::Location.load("Europe/Berlin")
  end

  it "raises an ART::Exceptions::BadRequest if a time could not be parsed from the string" do
    configuration = ART::TimeConverter::Configuration(Time).new "time", ART::TimeConverter
    request = new_request
    request.attributes.set "time", "foo", String

    expect_raises ART::Exceptions::BadRequest, "Invalid date(time) for argument 'time'." do
      ART::TimeConverter.new.apply request, configuration
    end
  end
end
