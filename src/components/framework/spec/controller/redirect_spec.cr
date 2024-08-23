require "../spec_helper"

struct RedirectControllerTest < ASPEC::TestCase
  def test_empty_route_permanent : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    ex = expect_raises ATH::Exception::HTTPException do
      controller.redirect_url request, "", true
    end

    ex.status_code.should eq 410
  end

  def test_empty_route_non_permanent : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    ex = expect_raises ATH::Exception::HTTPException do
      controller.redirect_url request, ""
    end

    ex.status_code.should eq 404
  end

  def test_full_url : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    response = controller.redirect_url request, "http://foo.com/"
    self.assert_redirect_url response, "http://foo.com/"
    response.status.found?.should be_true
  end

  def test_non_standard_port : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "example.com"}
    controller = ATH::Controller::Redirect.new

    self.assert_redirect_url controller.redirect_url(request, "/foo", scheme: "http", http_port: 90), "http://example.com:90/foo"
    self.assert_redirect_url controller.redirect_url(request, "/foo", scheme: "https", https_port: 90), "https://example.com:90/foo"
  end

  def test_falls_back_on_controller_ports : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "example.com"}
    controller = ATH::Controller::Redirect.new 100, 200

    self.assert_redirect_url controller.redirect_url(request, "/foo", scheme: "http"), "http://example.com:100/foo"
    self.assert_redirect_url controller.redirect_url(request, "/foo", scheme: "https"), "https://example.com:200/foo"
  end

  def test_full_url_with_method_keep : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    response = controller.redirect_url request, "http://foo.com/", keep_request_method: true
    self.assert_redirect_url response, "http://foo.com/"
    response.status.temporary_redirect?.should be_true
  end

  # def test_url_redirect_default_ports : Nil
  # end

  # def test_url_redirect : Nil
  # end

  @[TestWith(
    {"http://www.example.com/redirect-path", "/redirect-path", ""},
    {"http://www.example.com/redirect-path?foo=bar", "/redirect-path?foo=bar", ""},
    {"http://www.example.com/redirect-path?f.o=bar", "/redirect-path", "f.o=bar"},
    {"http://www.example.com/redirect-path?f.o=bar&a.c=example", "/redirect-path?f.o=bar", "a.c=example"},
    {"http://www.example.com/redirect-path?f.o=bar&a.c=example&b.z=def", "/redirect-path?f.o=bar", "a.c=example&b.z=def"},
    {"http://www.example.com/redirect-path?val=one&val=two", "/redirect-path?val=one", "val=two"},
  )]
  def test_path_query_params(expected : String, path : String, query_string : String) : Nil
    scheme = "http"
    host = "www.example.com"
    port = 80

    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "#{host}:#{port}"}
    request.query = query_string if query_string != ""

    controller = ATH::Controller::Redirect.new

    self.assert_redirect_url controller.redirect_url(request, path, scheme: scheme, http_port: port), expected
  end

  private def assert_redirect_url(response : ATH::Response, expected : String) : Nil
    response.redirect?(expected).should be_true, failure_message: "Expected: '#{expected}'\n Got: '#{response.headers["location"]}'."
  end
end
