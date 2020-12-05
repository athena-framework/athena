require "../spec_helper"

private struct MockErrorRenderer
  include ART::ErrorRendererInterface

  def render(exception : ::Exception) : ART::Response
    ART::Response.new "ERR", 418, HTTP::Headers{"FOO" => "BAR"}
  end
end

private class MockException < ART::Exceptions::BadRequest
end

describe ART::Listeners::Error do
  it "converts an exception into a response and logs the exception as warning" do
    event = ART::Events::Exception.new new_request, MockException.new "Something went wrong"

    ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers.should eq HTTP::Headers{"FOO" => "BAR"}
    response.content.should eq "ERR"
  end

  describe "logging" do
    it "logs non HTTPExceptions as error" do
      ex = Exception.new "err"

      event = ART::Events::Exception.new new_request, ex

      Log.capture do |logs|
        ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

        logs.check :error, /Exception:err/
        logs.entry.exception.should be ex
      end
    end

    it "logs server HTTPExceptions as error" do
      ex = ART::Exceptions::NotImplemented.new "nope"

      event = ART::Events::Exception.new new_request, ex

      Log.capture do |logs|
        ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

        logs.check :error, /Athena::Routing::Exceptions::NotImplemented:nope/
        logs.entry.exception.should be ex
      end
    end

    it "logs validation errors as notice" do
      ex = ART::Exceptions::UnprocessableEntity.new "Vaidation tests failed"

      event = ART::Events::Exception.new new_request, ex

      Log.capture do |logs|
        ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

        logs.check :notice, /Athena::Routing::Exceptions::UnprocessableEntity:Vaidation tests failed/
        logs.entry.exception.should be ex
      end
    end

    it "does not include exception within 404 errors" do
      ex = ART::Exceptions::NotFound.new "Unknown route"

      event = ART::Events::Exception.new new_request, ex

      Log.capture do |logs|
        ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

        logs.check :warn, /Athena::Routing::Exceptions::NotFound:Unknown route/
        logs.entry.exception.should be_nil
      end
    end

    it "logs HTTPExceptions as warning" do
      ex = MockException.new "Something went wrong"

      event = ART::Events::Exception.new new_request, ex

      Log.capture do |logs|
        ART::Listeners::Error.new(MockErrorRenderer.new).call(event, AED::Spec::TracableEventDispatcher.new)

        logs.check :warn, /MockException:Something went wrong/
        logs.entry.exception.should be ex
      end
    end
  end
end
