require "../spec_helper"

struct AddLinkHeaderListenerTest < ASPEC::TestCase
  def test_no_links_attribute : Nil
    event = new_response_event

    ABM::Listeners::AddLinkHeader.new.on_response event

    event.response.headers["link"]?.should be_nil
  end

  def test_single_link : Nil
    request = new_request
    request.attributes.set "_links", [%(<https://hub.example.com/.well-known/mercure>; rel="mercure")], Array(String)

    event = new_response_event(request: request)

    ABM::Listeners::AddLinkHeader.new.on_response event

    event.response.headers.get("link").should eq [%(<https://hub.example.com/.well-known/mercure>; rel="mercure")]
  end

  def test_multiple_links : Nil
    request = new_request
    request.attributes.set "_links", [
      %(<https://hub1.example.com/.well-known/mercure>; rel="mercure"),
      %(<https://hub2.example.com/.well-known/mercure>; rel="mercure"),
    ], Array(String)

    event = new_response_event(request: request)

    ABM::Listeners::AddLinkHeader.new.on_response event

    event.response.headers.get("link").should eq [
      %(<https://hub1.example.com/.well-known/mercure>; rel="mercure"),
      %(<https://hub2.example.com/.well-known/mercure>; rel="mercure"),
    ]
  end

  def test_preserves_existing_link_headers : Nil
    request = new_request
    request.attributes.set "_links", [%(<https://hub.example.com/.well-known/mercure>; rel="mercure")], Array(String)

    response = AHTTP::Response.new
    response.headers.add "link", %(<https://example.com>; rel="preload")

    event = new_response_event(request: request, response: response)

    ABM::Listeners::AddLinkHeader.new.on_response event

    event.response.headers.get("link").should eq [
      %(<https://example.com>; rel="preload"),
      %(<https://hub.example.com/.well-known/mercure>; rel="mercure"),
    ]
  end
end
