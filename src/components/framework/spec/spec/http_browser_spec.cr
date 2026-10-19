require "../spec_helper"

@[ADI::Register]
class HTTPBrowserResettable
  include ACTR::Service::Resettable

  class_getter resets = 0

  def reset : Nil
    @@resets += 1
  end
end

@[ADI::Register]
class HTTPBrowserCloseable
  include ACTR::Service::Closeable

  class_getter closes = 0

  def close : Nil
    @@closes += 1
  end
end

class HTTPBrowserCookieController < ATH::Controller
  @[ARTA::Get("/browser/cookies/set")]
  def set_cookie : AHTTP::Response
    response = AHTTP::Response.new
    response.headers << ::HTTP::Cookie.new "key", "value", path: "/browser"
    response
  end

  @[ARTA::Get("/browser/cookies/clear")]
  def clear_cookie : AHTTP::Response
    response = AHTTP::Response.new
    response.headers.clear_cookie "key", path: "/browser"
    response
  end

  @[ARTA::Get("/browser/cookies")]
  def cookies(request : AHTTP::Request) : String
    request.headers["cookie"]? || ""
  end
end

struct HTTPBrowserTest < ATH::Spec::APITestCase
  def test_sends_cookies_received_from_previous_requests : Nil
    self.get "/browser/cookies/set"
    self.assert_browser_cookie_has_value "key", "value", path: "/browser"

    self.get("/browser/cookies").body.should eq %("key=value")
  end

  def test_explicit_cookies_take_precedence_over_the_cookie_jar : Nil
    self.get "/browser/cookies/set"

    self.get("/browser/cookies", headers: ::HTTP::Headers{"cookie" => "key=explicit"}).body.should eq %("key=explicit")
  end

  def test_only_sends_cookies_matching_the_request_path : Nil
    self.get "/browser/cookies/set"

    self.get "/test"
    self.request.headers["cookie"]?.should be_nil
  end

  def test_removes_cookies_cleared_by_a_response : Nil
    self.get "/browser/cookies/set"
    self.assert_browser_has_cookie "key", path: "/browser"

    self.get "/browser/cookies/clear"

    self.assert_browser_not_has_cookie "key", path: "/browser"
    self.get("/browser/cookies").body.should eq %("")
  end

  def test_resets_resettable_services_once_the_request_is_done : Nil
    resets = HTTPBrowserResettable.resets

    self.get "/test"

    self.assert_response_is_successful
    HTTPBrowserResettable.resets.should eq resets + 1
  end

  # The requests of a test share its container, so the test closes its services once it's done.
  def test_leaves_closeable_services_open_once_the_request_is_done : Nil
    closes = HTTPBrowserCloseable.closes

    self.get "/test"

    self.assert_response_is_successful
    HTTPBrowserCloseable.closes.should eq closes
  end
end
