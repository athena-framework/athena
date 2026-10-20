require "../../spec_helper"

private def new_session : AHTTP::Session
  AHTTP::Session.new AHTTP::Session::Storage.new AHTTP::Session::Storage::Handler::Null.new
end

describe AHK::Controller::ValueResolvers::Session do
  describe "#resolve" do
    it "with a parameter of another type" do
      request = new_request
      request.session = new_session

      AHK::Controller::ValueResolvers::Session.new.resolve(request, new_parameter).should be_nil
    end

    it "without a session" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Session).new "session"

      AHK::Controller::ValueResolvers::Session.new.resolve(new_request, parameter).should be_nil
    end

    it "with a request attribute of the same name" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Session).new "session"
      request = new_request
      request.session = new_session
      request.attributes.set "session", "foo"

      AHK::Controller::ValueResolvers::Session.new.resolve(request, parameter).should be_nil
    end

    it "with a session" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Session).new "session"
      request = new_request
      request.session = session = new_session

      AHK::Controller::ValueResolvers::Session.new.resolve(request, parameter).should be session
    end

    it "with a nilable parameter" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Session?).new "session"
      request = new_request
      request.session = session = new_session

      AHK::Controller::ValueResolvers::Session.new.resolve(request, parameter).should be session
    end

    it "with a lazily created session" do
      parameter = AHK::Controller::ParameterMetadata(AHTTP::Session).new "session"
      request = new_request
      session = new_session
      request.session_factory = -> { session }

      AHK::Controller::ValueResolvers::Session.new.resolve(request, parameter).should be session
    end
  end
end
