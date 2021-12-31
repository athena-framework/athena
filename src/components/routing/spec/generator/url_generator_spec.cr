require "../spec_helper"

struct URLGeneratorTest < ASPEC::TestCase
  def tear_down : Nil
    ART::RouteProvider.reset
  end

  def test_generate_default_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")))
      .generate("test", reference_type: :absolute_url).should eq "http://localhost/base/test"
  end

  def test_generate_secure_default_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", scheme: "https"))
      .generate("test", reference_type: :absolute_url).should eq "https://localhost/base/test"
  end

  def test_generate_non_standard_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", http_port: 8080))
      .generate("test", reference_type: :absolute_url).should eq "http://localhost:8080/base/test"
  end

  def test_generate_secure_non_standard_port : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base", scheme: "https", https_port: 8080))
      .generate("test", reference_type: :absolute_url).should eq "https://localhost:8080/base/test"
  end

  def test_generate_no_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/test")))
      .generate("test").should eq "/base/test"
  end

  def test_generate_with_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{foo}")))
      .generate("test", {"foo" => "bar"}).should eq "/base/test/bar"
  end

  def test_generate_nil_parameter : Nil
    self
      .generator(self.routes(ART::Route.new("/test.{format}", {"format" => nil})))
      .generate("test").should eq "/base/test"
  end

  def test_generate_nil_parameter_required : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}/bar", {"foo" => nil}

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test"
    end
  end

  def test_generate_not_passed_optional_parameter_in_between : Nil
    generator = self.generator self.routes ART::Route.new "/{slug}/{page}", {"slug" => "index", "page" => "0"}

    generator.generate("test", {"page" => 1}).should eq "/base/index/1"
    generator.generate("test").should eq "/base/"
  end

  @[DataProvider("query_param_provider")]
  def test_generate_extra_params(expected : String, key : String, value) : Nil
    self
      .generator(self.routes ART::Route.new "/test")
      .generate("test", {key => value}, reference_type: :absolute_url).should eq "http://localhost/base/test#{expected}"
  end

  def query_param_provider : Hash
    {
      "nil value"    => {"", "foo", nil},
      "string value" => {"?foo=bar", "foo", "bar"},
    }
  end

  def test_generate_extra_param_from_globals : Nil
    self
      .generator(self.routes(ART::Route.new("/test")), context: ART::RequestContext.new(base_url: "/base").set_parameter("bar", "bar"))
      .generate("test", {"foo" => "bar"}).should eq "/base/test?foo=bar"
  end

  def test_generate_param_from_globals : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{foo}")), context: ART::RequestContext.new(base_url: "/base").set_parameter("foo", "bar"))
      .generate("test").should eq "/base/test/bar"
  end

  def test_generate_param_from_globals_overrides_defaults : Nil
    self
      .generator(self.routes(ART::Route.new("/{_locale}", {"_locale" => "en"})), context: ART::RequestContext.new(base_url: "/base").set_parameter("_locale", "de"))
      .generate("test").should eq "/base/de"
  end

  def test_generate_localized_routes_preserve_the_good_locale_in_url : Nil
    routes = ART::RouteCollection.new

    routes.add "foo.en", ART::Route.new "/{_locale}/fork", {"_locale" => "en", "_canonical_route" => "foo"}, {"_locale" => /en/}
    routes.add "foo.fr", ART::Route.new "/{_locale}/fourchette", {"_locale" => "fr", "_canonical_route" => "foo"}, {"_locale" => /fr/}
    routes.add "fun.en", ART::Route.new "/fun", {"_locale" => "en", "_canonical_route" => "fun"}, {"_locale" => /en/}
    routes.add "fun.fr", ART::Route.new "/amusant", {"_locale" => "fr", "_canonical_route" => "fun"}, {"_locale" => /fr/}

    ART.compile routes

    generator = self.generator routes
    generator.context.set_parameter "_locale", "fr"

    generator.generate("foo").should eq "/base/fr/fourchette"
    generator.generate("foo.en").should eq "/base/en/fork"
    generator.generate("foo", {"_locale" => "en"}).should eq "/base/en/fork"
    generator.generate("foo.fr", {"_locale" => "en"}).should eq "/base/fr/fourchette"

    generator.generate("fun").should eq "/base/amusant"
    generator.generate("fun.en").should eq "/base/fun"
    generator.generate("fun", {"_locale" => "en"}).should eq "/base/fun"
    generator.generate("fun.fr", {"_locale" => "en"}).should eq "/base/amusant"
  end

  def test_generate_invalid_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    generator = self.generator routes, default_locale: "fr"

    expect_raises ART::Exception::RouteNotFound do
      generator.generate name
    end
  end

  def test_generate_default_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, default_locale: "hr")
      .generate(name, reference_type: :absolute_url).should eq "http://localhost/base/foo"
  end

  def test_generate_overridden_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, default_locale: "hr")
      .generate(name, {"_locale" => "en"}, :absolute_url).should eq "http://localhost/base/bar"
  end

  def test_generate_overridden_via_request_context_locale : Nil
    routes = ART::RouteCollection.new
    name = "test"

    {"hr" => "/foo", "en" => "/bar"}.each do |locale, path|
      routes.add "#{name}.#{locale}", ART::Route.new path, {"_locale" => locale, "_canonical_route" => name}, {"_locale" => locale}
    end

    ART.compile routes

    self
      .generator(routes, context: ART::RequestContext.new(base_url: "/base").set_parameter("_locale", "en"), default_locale: "hr")
      .generate(name, reference_type: :absolute_url).should eq "http://localhost/base/bar"
  end

  def test_generate_no_routes : Nil
    generator = self.generator self.routes ART::Route.new "/test"

    expect_raises ART::Exception::RouteNotFound do
      generator.generate("foo", reference_type: :absolute_url)
    end
  end

  def test_generate_missing_required_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}"

    expect_raises ART::Exception::MissingRequiredParameters, %(Cannot generate URL for route 'test'. Missing required parameters: 'foo'.) do
      generator.generate("test", reference_type: :absolute_url)
    end
  end

  def test_generate_invalid_optional_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}

    expect_raises ART::Exception::InvalidParameter, "Parameter 'foo' for route 'test' must match '(?-imsx:\\d+)' (got 'bar') to generate the corresponding URL." do
      generator.generate("test", {"foo" => "bar"}, :absolute_url)
    end
  end

  def test_generate_invalid_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", requirements: {"foo" => /1|2/}

    expect_raises ART::Exception::InvalidParameter, "Parameter 'foo' for route 'test' must match '(?-imsx:1|2)' (got '0') to generate the corresponding URL." do
      generator.generate("test", {"foo" => "0"}, :absolute_url)
    end
  end

  def test_generate_invalid_optional_param_non_strict : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}
    generator.strict_requirements = false

    generator.generate("test", {"foo" => "bar"}, :absolute_url).should eq ""
  end

  def test_generate_invalid_param_disabled_checks : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", {"foo" => "1"}, {"foo" => /\d+/}
    generator.strict_requirements = nil

    generator.generate("test", {"foo" => "bar"}).should eq "/base/test/bar"
  end

  def test_generate_invalid_required_param : Nil
    generator = self.generator self.routes ART::Route.new "/test/{foo}", requirements: {"foo" => /1|2/}

    expect_raises ART::Exception::InvalidParameter do
      generator.generate("test", {"foo" => "0"}, :absolute_url)
    end
  end

  def test_generate_required_param_empty_string : Nil
    generator = self.generator self.routes ART::Route.new "/{slug}", requirements: {"slug" => /.+/}

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", {"slug" => ""}
    end
  end

  def test_generate_scheme_requirement_does_nothing_if_same_as_current_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "http")), context: ART::RequestContext.new base_url: "/base", scheme: "http")
      .generate("test").should eq "/base/"
  end

  def test_generate_scheme_requirement_does_nothing_if_same_as_current_scheme_secure : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "https")), context: ART::RequestContext.new base_url: "/base", scheme: "https")
      .generate("test").should eq "/base/"
  end

  def test_generate_scheme_requirement_forces_absolute_url : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "http")), context: ART::RequestContext.new base_url: "/base", scheme: "https")
      .generate("test").should eq "http://localhost/base/"
  end

  def test_generate_scheme_requirement_forces_absolute_url_secure : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: "https")))
      .generate("test").should eq "https://localhost/base/"
  end

  def test_generate_scheme_requirement_creates_url_for_first_required_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("/", schemes: {"Ftp", "https"})))
      .generate("test").should eq "ftp://localhost/base/"
  end

  def test_generate_scheme_requirement_creates_url_for_first_required_scheme : Nil
    self
      .generator(self.routes(ART::Route.new("//path-and-not-domain")), context: ART::RequestContext.new)
      .generate("test").should eq "/path-and-not-domain"
  end

  def test_generate_no_trailing_slash_for_multiple_optional_parameters : Nil
    self
      .generator(self.routes(ART::Route.new("/category/{slug1}/{slug2}/{slug3}", {"slug2" => nil, "slug3" => nil})))
      .generate("test", {"slug1" => "foo"}).should eq "/base/category/foo"
  end

  def test_generate_nil_for_optional_parameter_is_ignored : Nil
    self
      .generator(self.routes(ART::Route.new("/test/{default}", {"default" => "0"})))
      .generate("test", {"default" => nil}).should eq "/base/test"
  end

  def test_generate_query_param_same_as_default : Nil
    generator = self.generator self.routes ART::Route.new "/test", {"page" => 1}

    generator.generate("test", page: 2).should eq "/base/test?page=2"
    generator.generate("test", page: 1).should eq "/base/test"
    generator.generate("test", page: "1").should eq "/base/test"
    generator.generate("test").should eq "/base/test"
  end

  # TODO: Also support array defaults.

  def test_generate_special_route_name : Nil
    self
      .generator(self.routes(ART::Route.new("/bar"), name: "$péß^a|"))
      .generate("$péß^a|").should eq "/base/bar"
  end

  def test_generate_url_encoding : Nil
    expected_path = "/base/@:%5B%5D/%28%29*%27%22%20+,;-._~%26%24%3C%3E|%7B%7D%25%5C%5E%60!%3Ffoo=bar%23id/@:%5B%5D/%28%29*%27%22%20+,;-._~%26%24%3C%3E|%7B%7D%25%5C%5E%60!%3Ffoo=bar%23id?query=@:%5B%5D/%28%29*%27%22+%2B,;-._~%26%24%3C%3E%7C%7B%7D%25%5C%5E%60!?foo%3Dbar%23id"
    chars = "@:[]/()*'\" +,;-._~&$<>|{}%\\^`!?foo=bar#id"

    self
      .generator(self.routes(ART::Route.new("/#{chars}/{path}", requirements: {"path" => /.+/})))
      .generate("test", {"path" => chars, "query" => chars}).should eq expected_path
  end

  def test_generate_encoding_of_relative_path_segments_double_dot : Nil
    self
      .generator(self.routes(ART::Route.new("/dir/../dir/..")))
      .generate("test").should eq "/base/dir/%2E%2E/dir/%2E%2E"
  end

  def test_generate_encoding_of_relative_path_segments_single_dot : Nil
    self
      .generator(self.routes(ART::Route.new("/dir/./dir/.")))
      .generate("test").should eq "/base/dir/%2E/dir/%2E"
  end

  def test_generate_encoding_of_relative_path_segments_unencoded_dots : Nil
    self
      .generator(self.routes(ART::Route.new("/a./.a/a../..a/...")))
      .generate("test").should eq "/base/a./.a/a../..a/..."
  end

  def test_generate_encoding_of_slash_in_path : Nil
    self
      .generator(self.routes(ART::Route.new("/dir/{path}/dir2", requirements: {"path" => /.+/})))
      .generate("test", path: "foo/bar%2Fbaz").should eq "/base/dir/foo/bar%2Fbaz/dir2"
  end

  def test_generate_adjacent_variables : Nil
    generator = self.generator(self.routes(ART::Route.new("{x}{y}{z}.{_format}", {"z" => "default-z", "_format" => "html"}, {"y" => /\d+/})))

    generator.generate("test", x: "foo", y: 123).should eq "/base/foo123"
    generator.generate("test", x: "foo", y: 123, z: "bar", "_format": "xml").should eq "/base/foo123bar.xml"
  end

  def test_generate_optional_variable_with_no_real_separator : Nil
    generator = self.generator(self.routes(ART::Route.new("/get{what}", {"what" => "All"})))

    generator.generate("test").should eq "/base/get"
    generator.generate("test", what: "Sites").should eq "/base/getSites"
  end

  def test_generate_required_variable_with_no_real_separator : Nil
    self
      .generator(self.routes(ART::Route.new("/get{what}Suffix")))
      .generate("test", what: "Sites").should eq "/base/getSitesSuffix"
  end

  def test_generate_default_requirement_of_variable : Nil
    self
      .generator(self.routes(ART::Route.new("/{page}.{_format}")))
      .generate("test", page: "index", "_format": "mobile.html").should eq "/base/index.mobile.html"
  end

  def test_generate_important_variable : Nil
    generator = self.generator(self.routes(ART::Route.new("/{page}.{!_format}", {"_format" => "mobile.html"})))

    generator.generate("test", page: "index", "_format": "xml").should eq "/base/index.xml"
    generator.generate("test", page: "index", "_format": "mobile.html").should eq "/base/index.mobile.html"
    generator.generate("test", page: "index").should eq "/base/index.mobile.html"
  end

  def test_generate_important_variable_no_default : Nil
    generator = self.generator self.routes ART::Route.new "/{page}.{!_format}"

    expect_raises ART::Exception::MissingRequiredParameters do
      generator.generate "test", page: "index"
    end
  end

  def test_generate_default_requirement_of_variable_disallows_slash : Nil
    generator = self.generator self.routes ART::Route.new "/{page}.{!_format}"

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", page: "index", "_format": "sl/ash"
    end
  end

  def test_generate_default_requirement_of_variable_disallows_next_separator : Nil
    generator = self.generator self.routes ART::Route.new "/{page}.{!_format}"

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", page: "do.it", "_format": "html"
    end
  end

  def test_generate_host_different_than_context : Nil
    self
      .generator(self.routes(ART::Route.new("/{name}", host: "{locale}.example.com")))
      .generate("test", name: "George", locale: "fr").should eq "//fr.example.com/base/George"
  end

  def test_generate_host_same_as_context : Nil
    self
      .generator(self.routes(ART::Route.new("/{name}", host: "{locale}.example.com")), context: ART::RequestContext.new(base_url: "/base", host: "fr.example.com"))
      .generate("test", name: "George", locale: "fr").should eq "/base/George"
  end

  def test_generate_host_same_as_context_absolute_url : Nil
    self
      .generator(self.routes(ART::Route.new("/{name}", host: "{locale}.example.com")), context: ART::RequestContext.new(base_url: "/base", host: "fr.example.com"))
      .generate("test", {"name" => "George", "locale" => "fr"}, reference_type: :absolute_url).should eq "http://fr.example.com/base/George"
  end

  def test_url_invalid_parameter_in_host : Nil
    generator = self.generator self.routes ART::Route.new "/", requirements: {"foo" => /bar/}, host: "{foo}.example.com"

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", foo: "baz"
    end
  end

  def test_url_invalid_parameter_in_host_with_default : Nil
    generator = self.generator self.routes ART::Route.new "/", {"foo" => "bar"}, {"foo" => /bar/}, host: "{foo}.example.com"

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", foo: "baz"
    end
  end

  def test_url_invalid_parameter_in_host_with_default_and_matches_default : Nil
    generator = self.generator self.routes ART::Route.new "/", {"foo" => "baz"}, {"foo" => /bar/}, host: "{foo}.example.com"

    expect_raises ART::Exception::InvalidParameter do
      generator.generate "test", foo: "baz"
    end
  end

  def test_url_invalid_parameter_in_host_non_strict_mode : Nil
    generator = self.generator self.routes ART::Route.new "/", {"foo" => "bar"}, {"foo" => /bar/}, host: "{foo}.example.com"
    generator.strict_requirements = false

    generator.generate("test", foo: "baz").should be_empty
  end

  def test_generate_host_is_case_insensitive : Nil
    self
      .generator(self.routes(ART::Route.new("/", requirements: {"locale" => /en|de|fr/}, host: "{locale}.example.com")))
      .generate("test", locale: "EN", reference_type: :network_path).should eq "//EN.example.com/base/"
  end

  def test_generate_default_host_is_used_when_context_host_is_empty : Nil
    generator = self.generator(self.routes(ART::Route.new("/path", {"domain" => "my.fallback.host"}, {"domain" => /.+/}, host: "{domain}")))
    generator.context.host = ""

    generator.generate("test", reference_type: :absolute_url).should eq "http://my.fallback.host/base/path"
  end

  def test_generate_default_host_is_used_when_context_host_is_empty_and_path_reference_type : Nil
    generator = self.generator(self.routes(ART::Route.new("/path", {"domain" => "my.fallback.host"}, {"domain" => /.+/}, host: "{domain}")))
    generator.context.host = ""

    generator.generate("test").should eq "//my.fallback.host/base/path"
  end

  def test_generate_absolute_url_fallback_to_path_if_host_is_empty_and_scheme_is_https : Nil
    generator = self.generator self.routes ART::Route.new "/route"
    generator.context.host = ""
    generator.context.scheme = "https"

    generator.generate("test", reference_type: :absolute_url).should eq "/base/route"
  end

  def test_generate_absolute_url_fallback_to_network_if_scheme_is_empty_and_host_is_not : Nil
    generator = self.generator self.routes ART::Route.new "/route"
    generator.context.host = "example.com"
    generator.context.scheme = ""

    generator.generate("test", reference_type: :absolute_url).should eq "//example.com/base/route"
  end

  def test_generate_absolute_url_fallback_to_path_if_scheme_and_host_are_empty : Nil
    generator = self.generator self.routes ART::Route.new "/route"
    generator.context.host = ""
    generator.context.scheme = ""

    generator.generate("test", reference_type: :absolute_url).should eq "/base/route"
  end

  def test_generate_absolute_url_non_http_scheme_and_empty_host : Nil
    generator = self.generator self.routes ART::Route.new "/route", schemes: "file"
    generator.context.base_url = ""
    generator.context.host = ""

    generator.generate("test", reference_type: :absolute_url).should eq "file:///route"
  end

  def test_generate_network_paths : Nil
    routes = self.routes ART::Route.new "/{name}", host: "{locale}.example.com", schemes: "http"

    self
      .generator(routes)
      .generate("test", name: "George", locale: "de", reference_type: :network_path).should eq "//de.example.com/base/George"

    self
      .generator(routes, context: ART::RequestContext.new base_url: "/base", host: "de.example.com")
      .generate("test", name: "George", locale: "de", query: "string", reference_type: :network_path).should eq "//de.example.com/base/George?query=string"

    self
      .generator(routes, context: ART::RequestContext.new base_url: "/base", scheme: "https")
      .generate("test", name: "George", locale: "de", reference_type: :network_path).should eq "http://de.example.com/base/George"

    self
      .generator(routes)
      .generate("test", name: "George", locale: "de", reference_type: :absolute_url).should eq "http://de.example.com/base/George"
  end

  def test_generate_relative_path : Nil
    routes = ART::RouteCollection.new
    routes.add "article", ART::Route.new "/{author}/{article}/"
    routes.add "comments", ART::Route.new "/{author}/{article}/comments"
    routes.add "host", ART::Route.new "/{article}", host: "{author}.example.com"
    routes.add "scheme", ART::Route.new "/{author}/blog", schemes: "https"
    routes.add "unrelated", ART::Route.new "/about"

    ART.compile routes

    generator = self.generator routes, context: ART::RequestContext.new base_url: "/base", host: "example.com", path: "/George/athena-is-great/"

    generator.generate("comments", author: "George", article: "athena-is-great", reference_type: :relative_path).should eq "comments"
    generator.generate("comments", author: "George", article: "athena-is-great", page: 2, reference_type: :relative_path).should eq "comments?page=2"
    generator.generate("article", author: "George", article: "crystal-is-great", reference_type: :relative_path).should eq "../crystal-is-great/"
    generator.generate("article", author: "foo", article: "shards-is-great", reference_type: :relative_path).should eq "../../foo/shards-is-great/"
    generator.generate("host", author: "George", article: "crystal-is-great", reference_type: :relative_path).should eq "//George.example.com/base/crystal-is-great"
    generator.generate("scheme", author: "George", reference_type: :relative_path).should eq "https://example.com/base/George/blog"
    generator.generate("unrelated", reference_type: :relative_path).should eq "../../about"
  end

  # This is primarily just sanity checking the stdlib logic to ensure the correct methods are being used.
  def test_generate_relative_path_internal : Nil
    routes = ART::RouteCollection.new
    routes.add "one", ART::Route.new "/a/b/c/d"
    routes.add "two", ART::Route.new "/a/b/c/"
    routes.add "three", ART::Route.new "/a/b/"
    routes.add "four", ART::Route.new "/a/b/c/other"
    routes.add "five", ART::Route.new "/a/x/y"

    ART.compile routes

    generator = self.generator routes, context: ART::RequestContext.new path: "/a/b/c/d"

    generator.generate("one", reference_type: :relative_path).should eq ""
    generator.generate("two", reference_type: :relative_path).should eq "./"
    generator.generate("three", reference_type: :relative_path).should eq "../"
    generator.generate("four", reference_type: :relative_path).should eq "other"
    generator.generate("five", reference_type: :relative_path).should eq "../../x/y"
  end

  def test_generate_with_fragment : Nil
    generator = self.generator(self.routes(ART::Route.new("/")))

    generator.generate("test", "_fragment": "frag ment").should eq "/base/#frag%20ment"
    generator.generate("test", "_fragment": "0").should eq "/base/#0"
  end

  def test_generate_with_fragment_does_not_escape_valid_chars : Nil
    self
      .generator(self.routes(ART::Route.new("/")))
      .generate("test", "_fragment": "?/").should eq "/base/#?/"
  end

  def test_generate_with_fragment_via_default : Nil
    self
      .generator(self.routes(ART::Route.new("/", {"_fragment" => "fragment"})))
      .generate("test").should eq "/base/#fragment"
  end

  @[DataProvider("look_around_provider")]
  def test_generate_look_around_requirements_in_path(expected : String, path : String, requirement : Regex) : Nil
    self
      .generator(self.routes(ART::Route.new(path, requirements: {"foo" => requirement, "baz" => /.+?/})))
      .generate("test", foo: "a/b", baz: "c/d/e").should eq expected
  end

  def look_around_provider : Tuple
    {
      {"/base/a/b/b%28ar/c/d/e", "/{foo}/b(ar/{baz}", /.+(?=\/b\(ar\/)/},
      {"/base/a/b/bar/c/d/e", "/{foo}/bar/{baz}", /.+(?!$)/},
      {"/base/bar/a/b/bam/c/d/e", "/bar/{foo}/bam/{baz}", /(?<=\/bar\/).+/},
      {"/base/bar/a/b/bam/c/d/e", "/bar/{foo}/bam/{baz}", /(?<!^).+/},
    }
  end

  private def generator(routes : ART::RouteCollection, *, context : ART::RequestContext? = nil, default_locale : String? = nil) : ART::Generator::URLGenerator
    context = context || ART::RequestContext.new "/base"

    ART::Generator::URLGenerator.new context, default_locale
  end

  private def routes(route : ART::Route, *, name : String = "test") : ART::RouteCollection
    routes = ART::RouteCollection.new
    routes.add name, route

    ART.compile routes

    routes
  end
end
