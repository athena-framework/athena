require "../spec_helper"

private struct MockErrorRenderer
  include ATH::ErrorRendererInterface

  def render(exception : ::Exception) : ATH::Response
    ATH::Response.new "ERR", 418, HTTP::Headers{"FOO" => "BAR"}
  end
end

private class MockException < ATH::Exception::BadRequest
end

describe ATH::Listeners::Error do
  it "converts an exception into a response and logs the exception as warning" do
    event = ATH::Events::Exception.new new_request, MockException.new "Something went wrong"

    ATH::Listeners::Error.new(MockErrorRenderer.new).on_exception event

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["FOO"].should eq "BAR"
    response.content.should eq "ERR"
  end

  describe "logging" do
    it "logs non HTTPExceptions as error" do
      event = ATH::Events::Exception.new new_request, Exception.new "err"

      Log.capture do |logs|
        ATH::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :error, /Exception:err/
      end
    end

    it "logs server HTTPExceptions as error" do
      event = ATH::Events::Exception.new new_request, ATH::Exception::NotImplemented.new "nope"

      Log.capture do |logs|
        ATH::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :error, /Athena::Framework::Exception::NotImplemented:nope/
      end
    end

    it "logs validation errors as notice" do
      event = ATH::Events::Exception.new new_request, ATH::Exception::UnprocessableEntity.new "Validation tests failed"

      Log.capture do |logs|
        ATH::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :notice, /Athena::Framework::Exception::UnprocessableEntity:Validation tests failed/
      end
    end

    it "logs HTTPExceptions as warning" do
      event = ATH::Events::Exception.new new_request, MockException.new "Something went wrong"

      Log.capture do |logs|
        ATH::Listeners::Error.new(MockErrorRenderer.new).on_exception event

        logs.check :warn, /MockException:Something went wrong/
      end
    end
  end
end
