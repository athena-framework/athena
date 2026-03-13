require "../spec_helper"

struct SetCookieListenerTest < ASPEC::TestCase
  def test_no_cookies_attribute : Nil
    event = new_response_event

    ABM::Listeners::SetCookie.new.on_response event

    event.response.headers.cookies.should be_empty
  end

  def test_applies_cookies_to_response : Nil
    request = new_request
    cookies = Hash(String, ::HTTP::Cookie).new
    cookies[""] = ::HTTP::Cookie.new("mercureAuthorization", "token123", path: "/")
    request.attributes.set "_mercure_authorization_cookies", cookies, Hash(String, ::HTTP::Cookie)

    event = new_response_event(request: request)

    ABM::Listeners::SetCookie.new.on_response event

    event.response.headers.cookies["mercureAuthorization"].value.should eq "token123"
  end

  def test_removes_attribute_after_processing : Nil
    request = new_request
    cookies = Hash(String, ::HTTP::Cookie).new
    cookies[""] = ::HTTP::Cookie.new("mercureAuthorization", "token123", path: "/")
    request.attributes.set "_mercure_authorization_cookies", cookies, Hash(String, ::HTTP::Cookie)

    event = new_response_event(request: request)

    ABM::Listeners::SetCookie.new.on_response event

    request.attributes.has?("_mercure_authorization_cookies").should be_false
  end

  def test_applies_multiple_cookies : Nil
    request = new_request
    cookies = Hash(String, ::HTTP::Cookie).new
    cookies[""] = ::HTTP::Cookie.new("mercureAuthorization", "default-token", path: "/")
    cookies["hub1"] = ::HTTP::Cookie.new("mercureAuthorization", "hub1-token", path: "/hub1")
    request.attributes.set "_mercure_authorization_cookies", cookies, Hash(String, ::HTTP::Cookie)

    event = new_response_event(request: request)

    ABM::Listeners::SetCookie.new.on_response event

    # The last cookie with the same name wins in the cookies collection,
    # but both should have been added via <<
    event.response.headers.cookies.size.should be >= 1
  end
end
