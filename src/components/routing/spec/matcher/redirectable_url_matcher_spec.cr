require "../spec_helper"
require "./abstract_url_matcher_test_case"

private class MockRedirectableURLMatcher < ART::Matcher::URLMatcher
  include ART::Matcher::RedirectableURLMatcherInterface

  class_setter return_value : Hash(String, String?) = Hash(String, String?).new
  class_setter was_called : Bool = true
  class_setter expected_path : String? = nil
  class_setter expected_route : String? = nil
  class_setter expected_scheme : String? = nil

  def redirect(path : String, route : String, scheme : String? = nil) : Hash(String, String?)?
    @@was_called.should be_true

    if ep = @@expected_path
      path.should eq ep
    end

    if er = @@expected_route
      route.should eq er
    end

    if es = @@expected_scheme
      scheme.should eq es
    end

    @@return_value
  ensure
    @@return_value = Hash(String, String?).new
    @@was_called = true
    @@expected_path = nil
    @@expected_route = nil
    @@expected_scheme = nil
  end
end

struct RedirectableURLMatcherTest < AbstractURLMatcherTestCase
  def test_match_missing_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "test"})
  end

  def test_match_extra_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo"
    end

    self.get_matcher(routes).match("/foo/").should eq({"_route" => "test"})
  end

  def test_redirect_when_no_slash_for_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end
  end

  # TODO: Uncomment scheme check when supported
  def test_scheme_redirect_redirects_to_first_scheme : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: {"FTP", "HTTPS"}
    end

    MockRedirectableURLMatcher.expected_path = "/foo"
    MockRedirectableURLMatcher.expected_route = "test"
    # MockRedirectableURLMatcher.expected_scheme = "ftp"

    self.get_matcher(routes).match("/foo").should eq({"_route" => "test"})
  end

  # TODO: Enable when schemes are supported
  def ptest_no_schema_redirect_if_one_of_multiple_schemas_matches : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: {"https", "http"}
    end

    MockRedirectableURLMatcher.was_called = false

    self.get_matcher(routes).match("/foo").should eq({"_route" => "test"})
  end

  # TODO: Enable when schemes are supported
  def ptest_scheme_redirect_with_params : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/{bar}", schemes: "https"
    end

    MockRedirectableURLMatcher.return_value = {"redirect" => "value"} of String => String?
    MockRedirectableURLMatcher.expected_path = "/foo/baz"
    MockRedirectableURLMatcher.expected_route = "test"
    # MockRedirectableURLMatcher.expected_scheme = "https"

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "test", "bar" => "baz", "redirect" => "value"})
  end

  def test_scheme_redirect_for_root : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/", schemes: "https"
    end

    MockRedirectableURLMatcher.return_value = {"redirect" => "value"} of String => String?
    MockRedirectableURLMatcher.expected_path = "/"
    MockRedirectableURLMatcher.expected_route = "test"
    # MockRedirectableURLMatcher.expected_scheme = "https"

    self.get_matcher(routes).match("/").should eq({"_route" => "test", "redirect" => "value"})
  end

  def test_slash_redirect_with_params : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/{bar}/"
    end

    MockRedirectableURLMatcher.return_value = {"redirect" => "value"} of String => String?
    MockRedirectableURLMatcher.expected_path = "/foo/baz/"
    MockRedirectableURLMatcher.expected_route = "test"

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "test", "bar" => "baz", "redirect" => "value"})
  end

  def test_redirect_preserves_url_encoding : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo:bar/"
    end

    MockRedirectableURLMatcher.expected_path = "/foo%3Abar/"

    self.get_matcher(routes).match("/foo%3Abar").should eq({"_route" => "test"})
  end

  def test_match_scheme_requirement : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: "https"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "test"})
  end

  def test_fallback_page1 : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/"
      add "bar", ART::Route.new "/{name}"
    end

    MockRedirectableURLMatcher.expected_path = "/foo/"
    MockRedirectableURLMatcher.expected_route = "foo"

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
  end

  def test_fallback_page2 : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
      add "bar", ART::Route.new "/{name}/"
    end

    MockRedirectableURLMatcher.expected_path = "/foo"
    MockRedirectableURLMatcher.expected_route = "foo"

    self.get_matcher(routes).match("/foo/").should eq({"_route" => "foo"})
  end

  def test_missing_trailing_slash_and_scheme : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", schemes: "https"
    end

    MockRedirectableURLMatcher.expected_path = "/foo/"
    MockRedirectableURLMatcher.expected_route = "foo"
    # MockRedirectableURLMatcher.expected_scheme = "https"

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
  end

  def test_slash_and_verb_precedence_with_redirection : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/api/customers/{customerId}/contactpersons", methods: "POST"
      add "b", ART::Route.new "/api/customers/{customerId}/contactpersons/", methods: "GET"
    end

    matcher = self.get_matcher routes
    expected = {"_route" => "b", "customerId" => "123"}

    matcher.match("/api/customers/123/contactpersons/").should eq expected

    MockRedirectableURLMatcher.expected_path = "/api/customers/123/contactpersons/"

    matcher.match("/api/customers/123/contactpersons").should eq expected
  end

  def test_non_greedy_trailing_requirement : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{a}", requirements: {"a" => /\d+/}
    end

    MockRedirectableURLMatcher.expected_path = "/123"

    self.get_matcher(routes).match("/123/").should eq({"_route" => "a", "a" => "123"})
  end

  def test_match_greedy_trailing_requirement_default1 : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/fr-fr/{a}", {"a" => "aaa"}, {"a" => /.+/}
    end

    self.get_matcher(routes).match("/fr-fr/").should eq({"_route" => "a", "a" => "aaa"})
  end

  private def get_matcher(routes : ART::RouteCollection, context : ART::RequestContext = ART::RequestContext.new) : ART::Matcher::URLMatcher
    ART.compile routes
    MockRedirectableURLMatcher.new context
  end
end
