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

  def test_full_url_with_method_keep : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    response = controller.redirect_url request, "http://foo.com/", keep_request_method: true
    self.assert_redirect_url response, "http://foo.com/"
    response.status.temporary_redirect?.should be_true
  end

  def test_protocol_relative : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    response = controller.redirect_url request, "//foo.bar/"
    self.assert_redirect_url response, "http://foo.bar/"
    response.status.found?.should be_true
  end

  def test_url_redirect_default_ports : Nil
    host = "www.example.com"
    path = "/redirect-path"
    http_port = 1080
    https_port = 1443

    expected_url = "https://#{host}:#{https_port}#{path}"
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "#{host}:#{http_port}"}
    controller = ATH::Controller::Redirect.new https_port: https_port
    response = controller.redirect_url request, path, scheme: "https"
    self.assert_redirect_url response, expected_url

    expected_url = "http://#{host}:#{http_port}#{path}"
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "#{host}:#{http_port}"}
    controller = ATH::Controller::Redirect.new http_port
    response = controller.redirect_url request, path, scheme: "http"
    self.assert_redirect_url response, expected_url
  end

  @[DataProvider("url_redirect_provider")]
  def test_url_redirect(
    scheme : String,
    http_port : Int32?,
    https_port : Int32?,
    request_scheme : String,
    request_port : Int32,
    expected_port : String,
  ) : Nil
    host = "www.example.com"
    path = "/redirect-path"
    expected_url = "#{scheme}://#{host}#{expected_port}#{path}"

    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => "#{host}:#{request_port}"}
    request.scheme = request_scheme
    controller = ATH::Controller::Redirect.new

    response = controller.redirect_url request, path, scheme: scheme, http_port: http_port, https_port: https_port
    self.assert_redirect_url response, expected_url
  end

  def url_redirect_provider : Tuple
    {
      # Standard ports
      {"http", nil, nil, "http", 80, ""},
      {"http", 80, nil, "http", 80, ""},
      {"https", nil, nil, "http", 80, ""},
      {"https", 80, nil, "http", 80, ""},

      {"http", nil, nil, "https", 443, ""},
      {"http", nil, 443, "https", 443, ""},
      {"https", nil, nil, "https", 443, ""},
      {"https", nil, 443, "https", 443, ""},

      # Non-standard ports
      {"http", nil, nil, "http", 8080, ":8080"},
      {"http", 4080, nil, "http", 8080, ":4080"},
      {"http", 80, nil, "http", 8080, ""},
      {"https", nil, nil, "http", 8080, ""},
      {"https", nil, 8443, "http", 8080, ":8443"},
      {"https", nil, 443, "http", 8080, ""},

      {"https", nil, nil, "https", 8443, ":8443"},
      {"https", nil, 4443, "https", 8443, ":4443"},
      {"https", nil, 443, "https", 8443, ""},
      {"http", nil, nil, "https", 8443, ""},
      {"http", 8080, 4443, "https", 8443, ":8080"},
      {"http", 80, 4443, "https", 8443, ""},
    }
  end

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

  # TODO: For when we have a way to redirect to a route vs just a path

  # def test_redirect_with_query : Nil
  # end

  # def test_redirect_with_query_with_route_params_overriding : Nil
  # end

  private def assert_redirect_url(response : ATH::Response, expected : String) : Nil
    response.redirect?(expected).should be_true, failure_message: "Expected: '#{expected}'\n Got: '#{response.headers["location"]}'."
  end
end
