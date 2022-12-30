@[ASPEC::TestCase::Skip]
private struct MockWebTestCase < ATH::Spec::WebTestCase
  def initialize(@client : ATH::Spec::AbstractBrowser); end

  def create_client : ATH::Spec::AbstractBrowser
    @client
  end
end

private class MockClient < ATH::Spec::AbstractBrowser
  setter request : ATH::Request?
  setter response : HTTP::Server::Response?

  def do_request(request : ATH::Request) : NoReturn
    raise NotImplementedError.new "BUG: Invoked do_request method of MockClient"
  end
end

struct WebTestCaseTest < ASPEC::TestCase
  protected def before_all : Nil
    ATH::Request.register_format "custom", {"application/vnd.myformat"}
  end

  def test_assert_response_is_successful : Nil
    self.response_tester(new_response).assert_response_is_successful

    expect_raises Spec::AssertionFailed, "Failed asserting that the response is successful:\nHTTP/1.1 404 Not Found" do
      self.response_tester(new_response status: :not_found).assert_response_is_successful
    end
  end

  def test_assert_response_has_status : Nil
    self.response_tester(new_response).assert_response_has_status :ok
    self.response_tester(new_response status: :not_found).assert_response_has_status :not_found

    expect_raises Spec::AssertionFailed, "Failed asserting that the response status is 'OK':\nHTTP/1.1 404 Not Found" do
      self.response_tester(new_response status: :not_found).assert_response_has_status :ok
    end
  end

  def test_assert_response_is_redirected : Nil
    self.response_tester(new_response status: :moved_permanently).assert_response_redirects

    expect_raises Spec::AssertionFailed, "Failed asserting that the response is redirected:\nHTTP/1.1 200 OK" do
      self.response_tester(new_response).assert_response_redirects
    end
  end

  def test_assert_response_is_redirected_with_location : Nil
    self.response_tester(new_response status: :moved_permanently, headers: HTTP::Headers{"location" => "https://example.com"}).assert_response_redirects "https://example.com"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has header 'location' with value 'https://example.com'." do
      self.response_tester(new_response status: :moved_permanently).assert_response_redirects "https://example.com"
    end
  end

  def test_assert_response_is_redirected_with_status : Nil
    self.response_tester(new_response status: :moved_permanently).assert_response_redirects status: :moved_permanently

    expect_raises Spec::AssertionFailed, "Failed asserting that the response status is 'FOUND':\nHTTP/1.1 301 Moved Permanently" do
      self.response_tester(new_response status: :moved_permanently).assert_response_redirects status: 302
    end
  end

  def test_assert_response_format_equals : Nil
    self.response_tester(new_response headers: HTTP::Headers{"content-type" => "application/vnd.myformat"}).assert_response_format_equals "custom"
    self.response_tester(new_response headers: HTTP::Headers{"content-type" => "application/json"}).assert_response_format_equals "json"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response format is 'json':\nHTTP/1.1 200 OK" do
      self.response_tester(new_response headers: HTTP::Headers{"content-type" => "text/html"}).assert_response_format_equals "json"
    end
  end

  def test_assert_response_has_header : Nil
    self.response_tester(new_response headers: HTTP::Headers{"foo" => "bar"}).assert_response_has_header "foo"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has header 'baz'." do
      self.response_tester(new_response).assert_response_has_header "baz"
    end
  end

  def test_assert_response_not_has_header : Nil
    self.response_tester(new_response).assert_response_not_has_header "baz"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response does not have header 'foo'." do
      self.response_tester(new_response headers: HTTP::Headers{"foo" => "bar"}).assert_response_not_has_header "foo"
    end
  end

  def test_assert_response_header_equals : Nil
    self.response_tester(new_response headers: HTTP::Headers{"foo" => "bar"}).assert_response_header_equals "foo", "bar"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has header 'foo' with value 'bar'" do
      self.response_tester(new_response).assert_response_header_equals "foo", "bar"
    end

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has header 'baz' with value 'blah'." do
      self.response_tester(new_response headers: HTTP::Headers{"baz" => "bar"}).assert_response_header_equals "baz", "blah"
    end
  end

  def test_assert_response_not_header_equals : Nil
    self.response_tester(new_response headers: HTTP::Headers{"foo" => "baz"}).assert_response_header_not_equals "foo", "bar"

    expect_raises Spec::AssertionFailed, "ailed asserting that the response does not have header 'foo' with value 'bar'." do
      self.response_tester(new_response headers: HTTP::Headers{"foo" => "bar"}).assert_response_header_not_equals "foo", "bar"
    end
  end

  def test_assert_response_has_cookie : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar"

    self.response_tester(response).assert_response_has_cookie "foo"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has cookie 'foo'." do
      self.response_tester(new_response).assert_response_has_cookie "foo"
    end
  end

  def test_assert_response_not_has_cookie : Nil
    self.response_tester(new_response).assert_response_not_has_cookie "foo"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response does not have cookie 'foo'." do
      response = new_response
      response.cookies << HTTP::Cookie.new "foo", "bar"
      self.response_tester(response).assert_response_not_has_cookie "foo"
    end
  end

  def test_assert_cookie_has_value : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar"

    self.response_tester(response).assert_cookie_has_value "foo", "bar"

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has cookie 'foo'." do
      self.response_tester(new_response).assert_cookie_has_value "foo", "bar"
    end

    expect_raises Spec::AssertionFailed, "Failed asserting that the response has cookie 'foo' with value 'bar'." do
      response = new_response
      response.cookies << HTTP::Cookie.new "foo", "baz"

      self.response_tester(response).assert_cookie_has_value "foo", "bar"
    end
  end

  def test_assert_request_attribute_equals : Nil
    self.request_tester.assert_request_attribute_equals "foo", "bar"

    expect_raises Spec::AssertionFailed, "Failed asserting that the request has attribute 'foo' with value 'baz'." do
      self.request_tester.assert_request_attribute_equals "foo", "baz"
    end
  end

  def test_assert_route_equals : Nil
    self.request_tester.assert_route_equals "index", {"foo" => "bar"}

    expect_raises Spec::AssertionFailed, "Failed asserting that the request has attribute '_route' with value 'articles'." do
      self.request_tester.assert_route_equals "articles"
    end
  end

  def test_exception_on_server_error : Nil
    response = new_response(
      status: :internal_server_error,
      headers: HTTP::Headers{
        "x-debug-exception-code"    => "500",
        "x-debug-exception-file"    => "/path/to/file:123:4",
        "x-debug-exception-class"   => "MyException",
        "x-debug-exception-message" => "Oh noes!",
      }
    )

    expect_raises Spec::AssertionFailed, "Caused By:\n  Oh noes! (MyException)\n    from /path/to/file:123:4" do
      self.response_tester(response).assert_response_is_successful
    end
  end

  private def response_tester(response : HTTP::Server::Response) : ATH::Spec::WebTestCase
    client = MockClient.new
    client.response = response

    client.request = ATH::Request.new "GET", "/"

    self.tester client
  end

  private def request_tester : ATH::Spec::WebTestCase
    client = MockClient.new

    request = ATH::Request.new "GET", "/"
    request.attributes.set "foo", "bar", String
    request.attributes.set "_route", "index", String
    client.request = request

    self.tester client
  end

  private def tester(client : ATH::Spec::AbstractBrowser) : ATH::Spec::WebTestCase
    MockWebTestCase.new client
  end
end
