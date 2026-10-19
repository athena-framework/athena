require "../spec_helper"

private def response_with_cookies(*cookies : ::HTTP::Cookie) : ::HTTP::Server::Response
  new_response.tap do |response|
    cookies.each { |cookie| response.cookies << cookie }
  end
end

struct CookieJarTest < ASPEC::TestCase
  def test_set_get : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set cookie = ::HTTP::Cookie.new "foo", "bar"

    cookie_jar.get("foo").should be cookie
    cookie_jar.get("foobar").should be_nil

    cookie_jar.set ::HTTP::Cookie.new "foo", "bar", expires: Time.utc - 1.day
    cookie_jar.get("foo").should be_nil
  end

  def test_expire : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar"
    cookie_jar.expire "foo"

    cookie_jar.get("foo").should be_nil
  end

  def test_all : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set cookie1 = ::HTTP::Cookie.new "foo", "bar"
    cookie_jar.set cookie2 = ::HTTP::Cookie.new "bar", "foo"

    cookie_jar.all.should eq [cookie1, cookie2]
  end

  def test_clear : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar"
    cookie_jar.set ::HTTP::Cookie.new "bar", "foo"

    cookie_jar.clear

    cookie_jar.all.should be_empty
  end

  def test_update_from_response : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies ::HTTP::Cookie.new "foo", "foo"

    cookie_jar.get("foo").try(&.value).should eq "foo"
  end

  def test_update_from_response_with_max_age : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("foo", "bar", max_age: Time::Span.zero),
      ::HTTP::Cookie.new("baz", "qux", max_age: 1.hour),
    )

    cookie_jar.get("foo").should be_nil
    cookie_jar.get("baz").should_not be_nil
  end

  def test_update_from_response_ignores_an_empty_domain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(::HTTP::Cookie.new("foo", "bar", domain: "")), URI.parse("http://example.com")

    cookie_jar.get("foo").try(&.domain).should eq "example.com"
  end

  def test_update_from_response_does_not_mutate_the_response_cookie : Nil
    response = response_with_cookies ::HTTP::Cookie.new "foo", "bar"

    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response, URI.parse("http://example.com/")

    response.cookies["foo"].domain.should be_nil
  end

  def test_update_from_response_ignores_the_secure_flag_without_https : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(::HTTP::Cookie.new("foo", "bar", secure: true)), URI.parse("http://example.com/")
    cookie_jar.update_from_response response_with_cookies(::HTTP::Cookie.new("baz", "qux", secure: true)), URI.parse("https://example.com/")

    cookie_jar.get("foo").try(&.secure).should be_false
    cookie_jar.get("baz").try(&.secure).should be_true
  end

  @[DataProvider("all_values_provider")]
  def test_all_values(uri : String, values : Array(String)) : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo_nothing", "foo"
    cookie_jar.set ::HTTP::Cookie.new "foo_expired", "foo", expires: Time.utc - 1.day
    cookie_jar.set ::HTTP::Cookie.new "foo_path", "foo", path: "/foo"
    cookie_jar.set ::HTTP::Cookie.new "foo_domain", "foo", path: "/", domain: ".example.com"
    cookie_jar.set ::HTTP::Cookie.new "foo_strict_domain", "foo", path: "/", domain: ".www4.example.com"
    cookie_jar.set ::HTTP::Cookie.new "foo_secure", "foo", path: "/", secure: true

    cookie_jar.all_values(URI.parse uri).keys.should eq values
  end

  def all_values_provider : Tuple
    {
      {"http://www.example.com", ["foo_nothing", "foo_domain"]},
      {"http://www.example.com/", ["foo_nothing", "foo_domain"]},
      {"http://foo.example.com/", ["foo_nothing", "foo_domain"]},
      {"http://foo.example1.com/", ["foo_nothing"]},
      {"https://foo.example.com/", ["foo_nothing", "foo_secure", "foo_domain"]},
      {"http://www.example.com/foo/bar", ["foo_nothing", "foo_path", "foo_domain"]},
      {"http://www4.example.com/", ["foo_nothing", "foo_domain", "foo_strict_domain"]},
    }
  end

  def test_cookie_expire_with_same_name_but_different_paths : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/foo"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/bar"
    cookie_jar.expire "foo", "/foo"

    cookie_jar.get("foo").should be_nil
    cookie_jar.all_values(URI.parse "http://example.com/").should be_empty
    cookie_jar.all_values(URI.parse "http://example.com/foo").should be_empty
    cookie_jar.all_values(URI.parse "http://example.com/bar").should eq({"foo" => "bar2"})
  end

  def test_cookie_expire_with_nil_path : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/"
    cookie_jar.expire "foo", nil

    cookie_jar.get("foo").should be_nil
    cookie_jar.all_values(URI.parse "http://example.com/").should be_empty
  end

  def test_cookie_expire_with_domain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/foo", domain: "example2.com"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/foo", domain: "example3.com"
    cookie_jar.expire "foo", "/foo", "example2.com"

    cookie_jar.get("foo", "/foo", "example2.com").should be_nil
    cookie_jar.get("foo", "/foo", "example3.com").should_not be_nil
  end

  def test_cookie_with_same_name_but_different_paths : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/foo"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/bar"

    cookie_jar.all_values(URI.parse "http://example.com/").should be_empty
    cookie_jar.all_values(URI.parse "http://example.com/foo").should eq({"foo" => "bar1"})
    cookie_jar.all_values(URI.parse "http://example.com/bar").should eq({"foo" => "bar2"})
  end

  def test_cookie_with_same_name_but_different_domains : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/", domain: "foo.example.com"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/", domain: "bar.example.com"

    cookie_jar.all_values(URI.parse "http://example.com/").should be_empty
    cookie_jar.all_values(URI.parse "http://foo.example.com/").should eq({"foo" => "bar1"})
    cookie_jar.all_values(URI.parse "http://bar.example.com/").should eq({"foo" => "bar2"})
  end

  def test_cookie_get_prefers_the_most_specific_domain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set parent = ::HTTP::Cookie.new "foo", "bar1", path: "/", domain: "example.com"
    cookie_jar.set child = ::HTTP::Cookie.new "foo", "bar2", path: "/", domain: "admin.example.com"

    cookie_jar.get("foo", "/", "admin.example.com").should be child
    cookie_jar.get("foo", "/", "www.example.com").should be parent

    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set child
    cookie_jar.set parent

    cookie_jar.get("foo", "/", "admin.example.com").should be child
    cookie_jar.get("foo", "/", "www.example.com").should be parent
  end

  def test_cookie_get_prefers_the_longest_path : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set root = ::HTTP::Cookie.new "foo", "bar1", path: "/"
    cookie_jar.set admin = ::HTTP::Cookie.new "foo", "bar2", path: "/admin"

    cookie_jar.get("foo", "/admin").should be admin
    cookie_jar.get("foo", "/").should be root
  end

  def test_all_values_prefers_the_most_specific_cookie : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/", domain: "admin.example.com"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/", domain: "example.com"

    cookie_jar.all_values(URI.parse "http://admin.example.com/").should eq({"foo" => "bar2"})
    cookie_jar.all_values(URI.parse "http://www.example.com/").should eq({"foo" => "bar1"})

    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar2", path: "/admin"
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar1", path: "/"

    cookie_jar.all_values(URI.parse "http://example.com/admin").should eq({"foo" => "bar2"})
    cookie_jar.all_values(URI.parse "http://example.com/").should eq({"foo" => "bar1"})
  end

  def test_cookie_get_with_subdomain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set cookie1 = ::HTTP::Cookie.new "foo", "bar", path: "/", domain: ".example.com"
    cookie_jar.set cookie2 = ::HTTP::Cookie.new "foo1", "bar", path: "/", domain: "test.example.com"

    cookie_jar.get("foo", "/", "foo.example.com").should be cookie1
    cookie_jar.get("foo", "/", "example.com").should be cookie1
    cookie_jar.get("foo1", "/", "test.example.com").should be cookie2
  end

  def test_cookie_get_with_wrong_subdomain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo1", "bar", path: "/", domain: "test.example.com"

    cookie_jar.get("foo1", "/", "foo.example.com").should be_nil
  end

  def test_cookie_get_with_subdirectory : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set cookie1 = ::HTTP::Cookie.new "foo", "bar", path: "/test", domain: ".example.com"
    cookie_jar.set cookie2 = ::HTTP::Cookie.new "foo1", "bar1", path: "/", domain: ".example.com"

    cookie_jar.get("foo", "/", ".example.com").should be_nil
    cookie_jar.get("foo", "/bar", ".example.com").should be_nil
    cookie_jar.get("foo", "/test", "example.com").should be cookie1
    cookie_jar.get("foo1", "/", "example.com").should be cookie2
    cookie_jar.get("foo1", "/bar", "example.com").should be cookie2

    cookie_jar.get("foo1", "/bar").should be cookie2
  end

  def test_cookie_with_wildcard_domain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.set ::HTTP::Cookie.new "foo", "bar", path: "/", domain: ".example.com"

    cookie_jar.all_values(URI.parse "http://www.example.com").should eq({"foo" => "bar"})
    cookie_jar.all_values(URI.parse "http://wwwexample.com").should be_empty
  end

  def test_cookie_path_matches_at_segment_boundaries : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("foo", "bar", path: "/foo"),
      ::HTTP::Cookie.new("baz", "qux", path: "/baz/"),
    ), URI.parse("http://example.com/")

    cookie_jar.all_values(URI.parse "http://example.com/foo").should eq({"foo" => "bar"})
    cookie_jar.all_values(URI.parse "http://example.com/foo/bar").should eq({"foo" => "bar"})
    cookie_jar.all_values(URI.parse "http://example.com/foobar").should be_empty
    cookie_jar.all_values(URI.parse "http://example.com/baz/qux").should eq({"baz" => "qux"})
    cookie_jar.all_values(URI.parse "http://example.com/baz").should be_empty

    cookie_jar.get("foo", "/foo/bar").try(&.value).should eq "bar"
    cookie_jar.get("foo", "/foobar").should be_nil
  end

  def test_update_from_response_defaults_the_path_to_the_uri_directory : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("foo", "bar"),
      ::HTTP::Cookie.new("baz", "qux", path: "relative"),
    ), URI.parse("http://example.com/admin/users")

    cookie_jar.get("foo", "/admin").try(&.path).should eq "/admin"
    cookie_jar.get("baz", "/admin").try(&.path).should eq "/admin"
    cookie_jar.get("foo", "/").should be_nil
  end

  def test_update_from_response_ignores_cookies_for_another_domain : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("foreign", "value", domain: "bank.example"),
      ::HTTP::Cookie.new("sibling", "value", domain: "other.example.com"),
      ::HTTP::Cookie.new("suffix", "value", domain: "ample.com"),
      ::HTTP::Cookie.new("parent", "value", domain: ".Example.com"),
      ::HTTP::Cookie.new("self", "value", domain: "www.example.com"),
    ), URI.parse("http://www.example.com/")
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("ip", "value", domain: "127.0.0.1"),
      ::HTTP::Cookie.new("ipsuffix", "value", domain: "0.0.1"),
    ), URI.parse("http://127.0.0.1/")

    cookie_jar.all.map(&.name).should eq ["parent", "self", "ip"]
    cookie_jar.all_values(URI.parse "http://bank.example/").should be_empty
  end

  def test_host_only_cookies_are_not_sent_to_subdomains : Nil
    cookie_jar = ATH::Spec::CookieJar.new
    cookie_jar.update_from_response response_with_cookies(
      ::HTTP::Cookie.new("host", "value"),
      ::HTTP::Cookie.new("domain", "value", domain: "example.com"),
    ), URI.parse("http://example.com/")

    cookie_jar.all_values(URI.parse "http://example.com/").should eq({"host" => "value", "domain" => "value"})
    cookie_jar.all_values(URI.parse "http://sub.example.com/").should eq({"domain" => "value"})
    cookie_jar.get("host", "/", "example.com").try(&.value).should eq "value"
    cookie_jar.get("host", "/", "sub.example.com").should be_nil
  end
end
