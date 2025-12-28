require "../spec_helper"

abstract struct AbstractURLMatcherTestCase < ASPEC::TestCase
  private abstract def get_matcher(routes : ART::RouteCollection, context : ART::RequestContext = ART::RequestContext.new) : ART::Matcher::URLMatcher

  def test_match_no_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_request : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    self.get_matcher(routes).match(::HTTP::Request.new "GET", "/foo").should eq({"_route" => "foo"})
  end

  def test_match_method_not_allowed : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "post"
    end

    ex = expect_raises ART::Exception::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST"]
  end

  def test_nilable_match_method_not_allowed : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "post"
    end

    self.get_matcher(routes).match?("/foo").should be_nil
  end

  def test_nilable_match_request_method_not_allowed : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "post"
    end

    self.get_matcher(routes).match?(::HTTP::Request.new("GET", "/foo")).should be_nil
  end

  def test_match_method_not_allowed_root : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/", methods: "get"
    end

    ex = expect_raises ART::Exception::MethodNotAllowed do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/"
    end

    ex.allowed_methods.should eq ["GET"]
  end

  def test_match_head_allowed_when_requirements_includes_get : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "get"
    end

    self.get_matcher(routes, ART::RequestContext.new method: "HEAD").match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_method_not_allowed_aggregates_allowed_methods : Nil
    routes = self.build_collection do
      add "foo1", ART::Route.new "/foo", methods: "post"
      add "foo2", ART::Route.new "/foo", methods: {"PUT", "DELETE"}
    end

    ex = expect_raises ART::Exception::MethodNotAllowed do
      self.get_matcher(routes).match "/foo"
    end

    ex.allowed_methods.should eq ["POST", "PUT", "DELETE"]
  end

  def test_nilable_match_returns_matched_pattern : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    self.get_matcher(routes).match?("/no-match").should be_nil
  end

  def test_nilable_match_request_returns_matched_pattern : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    self.get_matcher(routes).match?(::HTTP::Request.new "GET", "/no-match").should be_nil
  end

  def test_match_returns_matched_pattern : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/no-match"
    end

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "foo", "bar" => "baz"})
  end

  def test_match_defaults_are_merged : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}", {"def" => "test"}
    end

    self.get_matcher(routes).match("/foo/baz").should eq({"_route" => "foo", "bar" => "baz", "def" => "test"})
  end

  def test_match_returned_results_do_not_mutate_the_original_static_route : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", {"def" => "test"}
    end

    matcher = self.get_matcher routes

    parameters = matcher.match("/foo")
    parameters.should eq({"_route" => "foo", "def" => "test"})

    parameters.delete "_route"

    matcher.match("/foo").should eq({"_route" => "foo", "def" => "test"})
  end

  def test_match_returned_results_do_not_mutate_the_original_dynamic_route : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{id}"
    end

    matcher = self.get_matcher routes

    parameters = matcher.match("/foo/10")
    parameters.should eq({"_route" => "foo", "id" => "10"})

    parameters.delete "_route"

    matcher.match("/foo/10").should eq({"_route" => "foo", "id" => "10"})
  end

  def test_match_method_is_ignored_if_none_are_provided : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: {"GET", "HEAD"}
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})

    expect_raises ART::Exception::MethodNotAllowed do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "foo"})
    self.get_matcher(routes, ART::RequestContext.new method: "HEAD").match("/foo").should eq({"_route" => "foo"})
  end

  def test_match_optional_variable_as_first_segment : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{bar}/foo", {"bar" => "bar"}, {"bar" => /foo|bar/}
    end

    matcher = self.get_matcher routes
    matcher.match("/bar/foo").should eq({"_route" => "bar", "bar" => "bar"})
    matcher.match("/foo/foo").should eq({"_route" => "bar", "bar" => "foo"})

    routes = self.build_collection do
      add "bar", ART::Route.new "/{bar}", {"bar" => "bar"}, {"bar" => /foo|bar/}
    end

    ART::RouteProvider.reset

    matcher = self.get_matcher routes
    matcher.match("/foo").should eq({"_route" => "bar", "bar" => "foo"})
    matcher.match("/").should eq({"_route" => "bar", "bar" => "bar"})
  end

  def test_match_only_optional_variable : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}/{bar}", {"bar" => "bar", "foo" => "foo"}
    end

    matcher = self.get_matcher routes
    matcher.match("/").should eq({"_route" => "bar", "bar" => "bar", "foo" => "foo"})
    matcher.match("/a").should eq({"_route" => "bar", "bar" => "bar", "foo" => "a"})
    matcher.match("/a/b").should eq({"_route" => "bar", "bar" => "b", "foo" => "a"})
  end

  def test_match_with_prefix : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}"
      add_prefix "/b"
      add_prefix "/a"
    end

    self.get_matcher(routes).match("/a/b/foo").should eq({"_route" => "foo", "foo" => "foo"})
  end

  def test_match_with_dynamic_prefix : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}"
      add_prefix "/b"
      add_prefix "/{_locale}"
    end

    self.get_matcher(routes).match("/de/b/foo").should eq({"_route" => "foo", "_locale" => "de", "foo" => "foo"})
  end

  def test_match_special_route_name : Nil
    routes = self.build_collection do
      add "$péß^a|", ART::Route.new "/bar"
    end

    self.get_matcher(routes).match("/bar").should eq({"_route" => "$péß^a|"})
  end

  def test_match_important_variables : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{!_format}", {"_format" => "xml"}
    end

    self.get_matcher(routes).match("/index.xml").should eq({"_route" => "index", "_format" => "xml"})
  end

  def test_match_short_path_does_not_match_important_variable : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{!_format}", {"_format" => "xml"}
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/index"
    end
  end

  def test_match_short_path_matches_non_important_variable : Nil
    routes = self.build_collection do
      add "index", ART::Route.new "/index.{_format}", {"_format" => "xml"}
    end

    self.get_matcher(routes).match("/index.xml").should eq({"_route" => "index", "_format" => "xml"})
  end

  def test_match_trailing_encoded_new_line_is_not_overlooked : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo%0a"
    end
  end

  def test_match_non_alphanum : Nil
    chars = "!\"$%éà &'()*+,./:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ\\[]^_`abcdefghijklmnopqrstuvwxyz{|}~-"

    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/bar", requirements: {"foo" => /#{Regex.escape chars}/}
    end

    matcher = self.get_matcher routes
    matcher.match("/#{URI.encode_path_segment chars}/bar").should eq({"_route" => "foo", "foo" => chars})
    matcher.match(%(/#{chars.tr "%", "%25"}/bar)).should eq({"_route" => "foo", "foo" => chars})
  end

  def test_match_with_dot_in_requirements : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/bar", requirements: {"foo" => /.+/}
    end

    self.get_matcher(routes).match("/#{URI.encode_path_segment "\n"}/bar").should eq({"_route" => "foo", "foo" => "\n"})
  end

  def test_match_regression : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}"
      add "bar", ART::Route.new "/foo/bar/{foo}"
    end

    self.get_matcher(routes).match("/foo/bar/bar").should eq({"_route" => "bar", "foo" => "bar"})

    routes = self.build_collection do
      add "foo", ART::Route.new "/{bar}"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/"
    end
  end

  def test_match_multiple_params : Nil
    routes = self.build_collection do
      add "foo1", ART::Route.new "/foo/{a}/{b}"
      add "foo2", ART::Route.new "/foo/{a}/test/test/{b}"
      add "foo3", ART::Route.new "/foo/{a}/{b}/{c}/{d}"
    end

    self.get_matcher(routes).match("/foo/test/test/test/bar").should eq({"_route" => "foo2", "a" => "test", "b" => "bar"})
  end

  def test_match_default_requirements_for_optional_variables : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}", {"page" => "index", "_format" => "html"}
    end

    self.get_matcher(routes).match("/my-page.xml").should eq({"_route" => "test", "page" => "my-page", "_format" => "xml"})
  end

  def test_match_match_overridden_route : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo"
    end

    routes2 = self.build_collection do
      add "foo", ART::Route.new "/foo1"
    end

    routes.add routes2

    self.get_matcher(routes).match("/foo1").should eq({"_route" => "foo"})

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_match_matching_is_eager : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{foo}-{bar}-", requirements: {"foo" => /.+/, "bar" => ".+"}
    end

    self.get_matcher(routes).match("/text1-text2-text3-text4-").should eq({"_route" => "test", "foo" => "text1-text2-text3", "bar" => "text4"})
  end

  def test_match_adjacent_variables : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{w}{x}{y}{z}.{_format}", {"z" => "default-z", "_format" => "html"}, {"y" => /y|Y/}
    end

    matcher = self.get_matcher routes

    matcher.match("/wwwwwxYZ.xml").should eq({"_route" => "test", "_format" => "xml", "w" => "wwwww", "x" => "x", "y" => "Y", "z" => "Z"})
    matcher.match("/wwwwwxyZZZ").should eq({"_route" => "test", "_format" => "html", "w" => "wwwww", "x" => "x", "y" => "y", "z" => "ZZZ"})
    matcher.match("/wwwwwxy").should eq({"_route" => "test", "_format" => "html", "w" => "wwwww", "x" => "x", "y" => "y", "z" => "default-z"})

    expect_raises ART::Exception::ResourceNotFound do
      matcher.match "/wxy.html"
    end
  end

  def test_match_optional_variable_with_no_real_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/get{what}", {"what" => "All"}
    end

    matcher = self.get_matcher routes

    matcher.match("/get").should eq({"_route" => "test", "what" => "All"})
    matcher.match("/getSites").should eq({"_route" => "test", "what" => "Sites"})
  end

  def test_match_required_variable_with_no_real_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/get{what}Suffix"
    end

    self.get_matcher(routes).match("/getSitesSuffix").should eq({"_route" => "test", "what" => "Sites"})
  end

  def test_match_default_requirement_of_variable : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}"
    end

    self.get_matcher(routes).match("/index.mobile.html").should eq({"_route" => "test", "page" => "index", "_format" => "mobile.html"})
  end

  def test_match_default_requirement_of_variable_disallows_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/index.sl/ash"
    end
  end

  def test_match_default_requirement_of_variable_disallows_next_separator : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/{page}.{_format}", requirements: {"_format" => /html|xml/}
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/do.t.html"
    end
  end

  def test_match_missing_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_match_extra_trailing_slash : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo/"
    end
  end

  def test_match_missing_trailing_slash_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo/"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end
  end

  def test_match_extra_trailing_slash_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo/"
    end
  end

  def test_match_scheme_requirement : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: "https"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_match_scheme_requirement_non_safe_method : Nil
    routes = self.build_collection do
      add "test", ART::Route.new "/foo", schemes: "https"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new method: "POST").match "/foo"
    end
  end

  def test_match_same_path_with_different_scheme : Nil
    routes = self.build_collection do
      add "https_route", ART::Route.new "/", schemes: "https"
      add "http_route", ART::Route.new "/", schemes: "http"
    end

    self.get_matcher(routes).match("/").should eq({"_route" => "http_route"})
  end

  def test_match_condition : Nil
    routes = self.build_collection do
      route = ART::Route.new "/foo"
      route.condition do |ctx|
        "POST" == ctx.method
      end

      add "foo", route
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/foo"
    end
  end

  def test_match_request_condition : Nil
    routes = self.build_collection do
      route = ART::Route.new "/foo/{bar}"
      route.condition do |_, request|
        request.path.starts_with? "/foo"
      end

      add "foo", route

      route = ART::Route.new "/foo/{bar}"
      route.condition do |_, request|
        "/foo/foo" == request.path
      end

      add "bar", route
    end

    self.get_matcher(routes).match("/foo/bar").should eq({"_route" => "foo", "bar" => "bar"})
  end

  def test_match_decode_once : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{bar}"
    end

    self.get_matcher(routes).match("/foo/bar%2523").should eq({"_route" => "foo", "bar" => "bar%23"})
  end

  def test_match_cannot_rely_on_prefix : Nil
    routes = self.build_collection do
      sub_routes = self.build_collection do
        add "bar", ART::Route.new "/bar"
        add_prefix "/prefix"

        itself["bar"].path = "/new"
      end

      add sub_routes
    end

    self.get_matcher(routes).match("/new").should eq({"_route" => "bar"})
  end

  def test_match_with_host : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}", host: "{locale}.example.com"
    end

    self.get_matcher(routes, ART::RequestContext.new host: "de.example.com").match("/foo/bar").should eq({"_route" => "foo", "foo" => "bar", "locale" => "de"})
  end

  def test_match_with_host_on_collection : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}"
      add "bar", ART::Route.new "/bar/{foo}", host: "{locale}.example.com"
      set_host "{locale}.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "en.example.com"
    matcher.match("/foo/bar").should eq({"_route" => "foo", "foo" => "bar", "locale" => "en"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "en.example.com"
    matcher.match("/bar/bar").should eq({"_route" => "bar", "foo" => "bar", "locale" => "en"})
  end

  def test_match_variation_in_trailing_slash_with_host : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", host: "foo.example.com"
      add "bar", ART::Route.new "/foo", host: "bar.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_match_variation_in_trailing_slash_with_host_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/foo", host: "bar.example.com"
      add "foo", ART::Route.new "/foo/", host: "foo.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_match_variation_in_trailing_slash_with_host_and_variable : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/", host: "foo.example.com"
      add "bar", ART::Route.new "/{foo}", host: "bar.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_variation_in_trailing_slash_with_host_and_variable_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}", host: "bar.example.com"
      add "foo", ART::Route.new "/{foo}/", host: "foo.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_variation_in_trailing_slash_with_host_and_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", methods: "POST"
      add "bar", ART::Route.new "/foo", methods: "GET"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_match_variation_in_trailing_slash_with_host_and_method_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/foo", methods: "GET"
      add "foo", ART::Route.new "/foo/", methods: "POST"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/foo").should eq({"_route" => "bar"})
  end

  def test_match_variable_variation_in_trailing_slash_with_method : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/{foo}/", methods: "POST"
      add "bar", ART::Route.new "/{foo}", methods: "GET"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    # pp ART::RouteProvider
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_variable_variation_in_trailing_slash_with_method_reversed : Nil
    routes = self.build_collection do
      add "bar", ART::Route.new "/{foo}", methods: "GET"
      add "foo", ART::Route.new "/{foo}/", methods: "POST"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/bar/").should eq({"_route" => "foo", "foo" => "bar"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_mix_of_static_and_variable_variation_in_trailing_slash_with_hosts : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", host: "foo.example.com"
      add "bar", ART::Route.new "/{foo}", host: "bar.example.com"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new host: "foo.example.com"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new host: "bar.example.com"
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_mix_of_static_and_variable_variation_in_trailing_slash_with_methods : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/", methods: "POST"
      add "bar", ART::Route.new "/{foo}", methods: "GET"
    end

    matcher = self.get_matcher routes, ART::RequestContext.new method: "POST"
    matcher.match("/foo/").should eq({"_route" => "foo"})

    matcher = self.get_matcher routes, ART::RequestContext.new method: "GET"
    matcher.match("/foo").should eq({"_route" => "bar", "foo" => "foo"})
    matcher.match("/bar").should eq({"_route" => "bar", "foo" => "bar"})
  end

  def test_match_with_host_does_not_match
    routes = self.build_collection do
      add "foo", ART::Route.new "/foo/{foo}", host: "{locale}.example.com"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes, ART::RequestContext.new host: "example.com").match "/foo/bar"
    end
  end

  def test_match_path_is_case_sensitive
    routes = self.build_collection do
      add "foo", ART::Route.new "/{locale}", requirements: {"locale" => /EN|FR|DE/}
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/en"
    end
  end

  def test_match_host_is_case_insensitive
    routes = self.build_collection do
      add "foo", ART::Route.new "/", requirements: {"locale" => /EN|FR|DE/}, host: "{locale}.example.com"
    end

    self.get_matcher(routes, ART::RequestContext.new host: "en.example.com").match("/").should eq({"_route" => "foo", "locale" => "en"})
  end

  def test_match_no_configuration : Nil
    expect_raises ART::Exception::NoConfiguration do
      self.get_matcher(ART::RouteCollection.new).match "/"
    end
  end

  def test_match_nested_collection : Nil
    routes = self.build_collection do
      sub_collection = self.build_collection do
        add "a", ART::Route.new "/a"
        add "b", ART::Route.new "/b"
        add "c", ART::Route.new "/c"
        add_prefix "/p"
      end

      add sub_collection

      add "baz", ART::Route.new "/{baz}"

      sub_collection = self.build_collection do
        add "buz", ART::Route.new "/buz"
        add_prefix "/prefix"
      end

      add sub_collection
    end

    matcher = self.get_matcher routes
    matcher.match("/p/a").should eq({"_route" => "a"})
    matcher.match("/p").should eq({"_route" => "baz", "baz" => "p"})
    matcher.match("/prefix/buz").should eq({"_route" => "buz"})
  end

  def test_match_scheme_and_method_mismatch : Nil
    routes = self.build_collection do
      add "foo", ART::Route.new "/", schemes: "https", methods: "POST"
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/"
    end
  end

  def test_sibling_routes : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/a{a}", methods: "POST"
      add "b", ART::Route.new "/a{a}", methods: "PUT"
      add "c", ART::Route.new "/a{a}"

      add "d", ART::Route.new("/b{a}").condition { false }
      add "e", ART::Route.new("/{b}{a}").condition { false }

      add "f", ART::Route.new "/{b}{a}", requirements: {"b" => /b/}
    end

    matcher = self.get_matcher routes
    matcher.match("/aa").should eq({"_route" => "c", "a" => "a"})
    matcher.match("/be").should eq({"_route" => "f", "a" => "e", "b" => "b"})
  end

  def test_match_requirements_with_capture_groups : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{a}/{b}", requirements: {"a" => /(a|b)/}
    end

    self.get_matcher(routes).match("/a/b").should eq({"_route" => "a", "a" => "a", "b" => "b"})
  end

  def test_match_dot_all_with_catch_all : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{id}.html", requirements: {"id" => /.+/}
      add "b", ART::Route.new "/{all}", requirements: {"all" => /.+/}
    end

    self.get_matcher(routes).match("/foo/bar.html").should eq({"_route" => "a", "id" => "foo/bar"})
  end

  def test_match_host_pattern : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{app}/{action}/{unused}", host: "{host}"
    end

    self
      .get_matcher(routes, ART::RequestContext.new host: "foo")
      .match("/app/action/unused").should eq({"_route" => "a", "app" => "app", "action" => "action", "unused" => "unused", "host" => "foo"})
  end

  def test_match_host_with_dot : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/foo", host: "foo.example.com"
      add "b", ART::Route.new "/bar/{baz}"
    end

    self.get_matcher(routes).match("/bar/abc.123").should eq({"_route" => "b", "baz" => "abc.123"})
  end

  def test_match_slash_variant : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/foo/{bar}", requirements: {"bar" => /.*/}
    end

    self.get_matcher(routes).match("/foo/").should eq({"_route" => "a", "bar" => ""})
    self.get_matcher(routes).match("/foo/bar/").should eq({"_route" => "a", "bar" => "bar/"})
  end

  def test_match_slash_with_verb : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{foo}", methods: {"put", "delete"}
      add "b", ART::Route.new "/bar/"
    end

    self.get_matcher(routes).match("/bar/").should eq({"_route" => "b"})
  end

  def test_match_slash_with_verb_match_all : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/dav/{foo}", requirements: {"foo" => /.*/}, methods: {"get", "options"}
    end

    self
      .get_matcher(routes, ART::RequestContext.new method: "OPTIONS")
      .match("/dav/files/bar/").should eq({"_route" => "a", "foo" => "files/bar/"})
  end

  def test_match_slash_and_verb_precedence : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/api/customers/{customerId}/contactpersons/", methods: "POST"
      add "b", ART::Route.new "/api/customers/{customerId}/contactpersons", methods: "GET"
    end

    self.get_matcher(routes).match("/api/customers/123/contactpersons").should eq({"_route" => "b", "customerId" => "123"})
  end

  def test_match_slash_and_verb_precedence_reversed : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/api/customers/{customerId}/contactpersons/", methods: "GET"
      add "b", ART::Route.new "/api/customers/{customerId}/contactpersons", methods: "POST"
    end

    self.get_matcher(routes, ART::RequestContext.new method: "POST").match("/api/customers/123/contactpersons").should eq({"_route" => "b", "customerId" => "123"})
  end

  def test_match_greedy_trailing_requirement : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/{a}", requirements: {"a" => /.+/}
    end

    self.get_matcher(routes).match("/foo").should eq({"_route" => "a", "a" => "foo"})
    self.get_matcher(routes).match("/foo/").should eq({"_route" => "a", "a" => "foo/"})
  end

  def test_match_greedy_trailing_requirement_with_default : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/fr-fr/{a}", {"a" => "aaa"}, {"a" => /.+/}
      add "b", ART::Route.new "/en-en/{b}", {"b" => "bbb"}, {"b" => /.+/}
    end

    self.get_matcher(routes).match("/fr-fr").should eq({"_route" => "a", "a" => "aaa"})
    self.get_matcher(routes).match("/fr-fr/AAA").should eq({"_route" => "a", "a" => "AAA"})

    self.get_matcher(routes).match("/en-en").should eq({"_route" => "b", "b" => "bbb"})
    self.get_matcher(routes).match("/en-en/BBB").should eq({"_route" => "b", "b" => "BBB"})
  end

  def test_match_greedy_trailing_requirement_default1 : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/fr-fr/{a}", {"a" => "aaa"}, {"a" => /.+/}
    end

    expect_raises ART::Exception::ResourceNotFound do
      self.get_matcher(routes).match "/fr-fr/"
    end
  end

  def test_match_greedy_trailing_requirement_default2 : Nil
    routes = self.build_collection do
      add "b", ART::Route.new "/en-en/{b}", {"b" => "bbb"}, {"b" => /.*/}
    end

    self.get_matcher(routes).match("/en-en/").should eq({"_route" => "b", "b" => ""})
  end

  def test_match_restrictive_trailing_requirement_with_static_route_after : Nil
    routes = self.build_collection do
      add "a", ART::Route.new "/hello{_}", requirements: {"_" => /\/(?!\/)/}
      add "b", ART::Route.new "/hello"
    end

    self.get_matcher(routes).match("/hello/").should eq({"_route" => "a", "_" => "/"})
  end

  private def build_collection(&) : ART::RouteCollection
    routes = ART::RouteCollection.new

    with routes yield

    routes
  end
end
