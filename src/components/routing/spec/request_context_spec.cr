require "./spec_helper"

struct RequestContextTest < ASPEC::TestCase
  def test_constructor : Nil
    request_context = ART::RequestContext.new(
      "foo",
      "post",
      "foo.bar",
      "HTTPS",
      8080,
      444,
      "/baz",
      "bar=foobar",
    )

    request_context.base_url.should eq "foo"
    request_context.method.should eq "POST"
    request_context.host.should eq "foo.bar"
    request_context.scheme.should eq "https"
    request_context.http_port.should eq 8080
    request_context.https_port.should eq 444
    request_context.path.should eq "/baz"
    request_context.query_string.should eq "bar=foobar"
  end

  def test_getters_setters : Nil
    request_context = ART::RequestContext.new

    request_context.base_url = "foo"
    request_context.method = "POST"
    request_context.host = "foo.bar"
    request_context.scheme = "https"
    request_context.http_port = 8080
    request_context.https_port = 444
    request_context.path = "/baz"
    request_context.query_string = "bar=foobar"

    request_context.base_url.should eq "foo"
    request_context.method.should eq "POST"
    request_context.host.should eq "foo.bar"
    request_context.scheme.should eq "https"
    request_context.http_port.should eq 8080
    request_context.https_port.should eq 444
    request_context.path.should eq "/baz"
    request_context.query_string.should eq "bar=foobar"
  end

  def test_from_uri_with_base_url : Nil
    request_context = ART::RequestContext.from_uri "https://test.com:444/index.html"

    request_context.method.should eq "GET"
    request_context.host.should eq "test.com"
    request_context.scheme.should eq "https"
    request_context.http_port.should eq 80
    request_context.https_port.should eq 444
    request_context.base_url.should eq "/index.html"
    request_context.path.should eq "/"
  end

  def test_from_uri_trailing_slash : Nil
    request_context = ART::RequestContext.from_uri "http://test.com:8080/"

    request_context.scheme.should eq "http"
    request_context.host.should eq "test.com"
    request_context.http_port.should eq 8080
    request_context.https_port.should eq 443
    request_context.base_url.should eq "/"
    request_context.path.should eq "/"
  end

  def test_from_uri_without_trailing_slash : Nil
    request_context = ART::RequestContext.from_uri "https://test.com"

    request_context.scheme.should eq "https"
    request_context.host.should eq "test.com"
    request_context.base_url.should be_empty
    request_context.path.should eq "/"
  end

  def test_from_uri_empty : Nil
    request_context = ART::RequestContext.from_uri ""

    request_context.scheme.should eq "http"
    request_context.host.should eq "localhost"
    request_context.base_url.should be_empty
    request_context.path.should eq "/"
  end

  @[TestWith(
    {"http://foo.com\\bar"},
    {"\\\\foo.com/bar"},
    {"a\rb"},
    {"a\nb"},
    {"a\tb"},
    {"\0foo"},
    {"foo\0"},
    {" foo"},
    {"foo "},
    # {":"},
  )]
  def test_from_uri_invalid(uri : String) : Nil
    request_context = ART::RequestContext.from_uri uri

    request_context.scheme.should eq "http"
    request_context.host.should eq "localhost"
    request_context.base_url.should be_empty
    request_context.path.should eq "/"
  end

  def test_from_request : Nil
    request = ART::Request.new "GET", "/foo?bar=baz", headers: HTTP::Headers{"host" => "test.com:444"}

    request_context = ART::RequestContext.new
    request_context.apply request

    request_context.base_url.should be_empty
    request_context.method.should eq "GET"
    request_context.host.should eq "test.com"
    request_context.path.should eq "/foo"
    request_context.query_string.should eq "bar=baz"

    # Don't really have a way to determine these via `HTTP::Request` at the moment :/
    request_context.scheme.should eq "http"
    request_context.http_port.should eq 80
    request_context.https_port.should eq 443
  end

  def test_parameters : Nil
    request_context = ART::RequestContext.new
    request_context.parameters.should be_empty

    request_context.parameters = {"foo" => "bar"} of String => String?
    request_context.parameters.should eq({"foo" => "bar"})

    request_context.parameter("foo").should eq "bar"
  end

  def test_has_parameter : Nil
    request_context = ART::RequestContext.new
    request_context.has_parameter?("foo").should be_false
    request_context.set_parameter "foo", "bar"
    request_context.has_parameter?("foo").should be_true
  end
end
