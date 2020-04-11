require "../spec_helper"

describe ART::Listeners::View do
  it "with a Nil return type" do
    route = create_route(Nil) { }
    event = ART::Events::View.new new_request(route: route), ART::View.new nil

    ART::Listeners::View.new.call(event, TracableEventDispatcher.new)

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::NO_CONTENT
    response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
    response.content.should be_empty
  end

  it "with a non Nil return type" do
    event = ART::Events::View.new new_request, ART::View.new "DATA"

    ART::Listeners::View.new.call(event, TracableEventDispatcher.new)

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::OK
    response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
    response.content.should eq %("DATA")
  end
end
