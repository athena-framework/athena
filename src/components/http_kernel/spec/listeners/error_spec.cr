require "../spec_helper"

private struct MockErrorRenderer
  include AHK::ErrorRendererInterface

  def render(exception : ::Exception) : AHTTP::Response
    AHTTP::Response.new "ERR", 418, ::HTTP::Headers{"FOO" => "BAR"}
  end
end

private class MockException < AHK::Exception::BadRequest
end

describe AHK::Listeners::Error do
  it "converts an exception into a response and logs the exception as warning" do
    event = AHK::Events::Exception.new new_request, MockException.new "Something went wrong"

    AHK::Listeners::Error.new(MockErrorRenderer.new).on_exception event

    response = event.response.should_not be_nil
    response.status.should eq ::HTTP::Status::IM_A_TEAPOT
    response.headers["FOO"].should eq "BAR"
    response.content.should eq "ERR"
  end

  describe "logging" do
    it "logs non HTTPExceptions as error" do
      event = AHK::Events::Exception.new new_request, Exception.new "err"

      Log.capture do |logs|
        AHK::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :error, /Exception:err/
      end
    end

    it "logs server HTTPExceptions as error" do
      event = AHK::Events::Exception.new new_request, AHK::Exception::NotImplemented.new "nope"

      Log.capture do |logs|
        AHK::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :error, /Athena::HTTPKernel::Exception::NotImplemented:nope/
      end
    end

    it "logs validation errors as notice" do
      event = AHK::Events::Exception.new new_request, AHK::Exception::UnprocessableEntity.new "Validation tests failed"

      Log.capture do |logs|
        AHK::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :notice, /Athena::HTTPKernel::Exception::UnprocessableEntity:Validation tests failed/
      end
    end

    it "logs HTTPExceptions as warning" do
      event = AHK::Events::Exception.new new_request, MockException.new "Something went wrong"

      Log.capture do |logs|
        AHK::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :warn, /MockException:Something went wrong/
      end
    end
  end
end
