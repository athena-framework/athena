require "../spec_helper"

private struct MockErrorRenderer
  include ART::ErrorRendererInterface

  def render(exception : ::Exception) : ART::Response
    ART::Response.new "ERR", 418, HTTP::Headers{"FOO" => "BAR"}
  end
end

describe ART::Listeners::Error do
  it "converts an exception into a response" do
    event = ART::Events::Exception.new new_request, Exception.new "Something went wrong"

    ART::Listeners::Error.new(MockErrorRenderer.new).call(event, TracableEventDispatcher.new)

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers.should eq HTTP::Headers{"FOO" => "BAR"}
    response.io.rewind.gets_to_end.should eq "ERR"
  end
end
