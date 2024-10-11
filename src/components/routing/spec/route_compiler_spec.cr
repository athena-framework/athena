require "./spec_helper"

struct RouteCompilerTest < ASPEC::TestCase
  @[DataProvider("compiler_provider")]
  def test_compile(route : ART::Route, prefix : String, regex : Regex, variables : Set(String), tokens : Array(ART::CompiledRoute::Token)) : Nil
    compiled_route = route.compile
    compiled_route.static_prefix.should eq prefix
    compiled_route.regex.should eq regex
    compiled_route.variables.should eq variables
    compiled_route.tokens.should eq tokens
  end

  def compiler_provider : Hash
    {
      "static" => {
        ART::Route.new("/foo"),
        "/foo",
        /^\/foo$/,
        Set(String).new,
        [
          ART::CompiledRoute::Token.new(:text, "/foo"),
        ],
      },
      "single variable" => {
        ART::Route.new("/foo/{bar}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)$/,
        Set{"bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),

        ],
      },
      "variable with default value" => {
        ART::Route.new("/foo/{bar}", {"bar" => "bar"}),
        "/foo",
        /^\/foo(?:\/(?P<bar>[^\/]++))?$/,
        Set{"bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),

        ],
      },
      "several variable" => {
        ART::Route.new("/foo/{bar}/{foobar}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)\/(?P<foobar>[^\/]++)$/,
        Set{"bar", "foobar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),

        ],
      },
      "several variables with defaults" => {
        ART::Route.new("/foo/{bar}/{foobar}", {"bar" => "bar", "foobar" => ""}),
        "/foo",
        /^\/foo(?:\/(?P<bar>[^\/]++)(?:\/(?P<foobar>[^\/]++))?)?$/,
        Set{"bar", "foobar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),

        ],
      },
      "several variables with some having defaults" => {
        ART::Route.new("/foo/{bar}/{foobar}", {"bar" => "bar"}),
        "/foo",
        /^\/foo\/(?P<bar>[^\/]++)\/(?P<foobar>[^\/]++)$/,
        Set{"bar", "foobar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "foobar"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),

        ],
      },
      "optional variable as the first segment with default" => {
        ART::Route.new("/{bar}", {"bar" => "bar"}),
        "",
        /^\/(?P<bar>[^\/]++)?$/,
        Set{"bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
        ],
      },
      "optional variable as the first segment with requirement" => {
        ART::Route.new("/{bar}", {"bar" => "bar"}, {"bar" => /(foo|bar)/}),
        "",
        /^\/(?P<bar>(?:foo|bar))?$/,
        Set{"bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /(?:foo|bar)/, "bar"),
        ],
      },
      "only optional variables with defaults" => {
        ART::Route.new("/{foo}/{bar}", {"foo" => "foo", "bar" => "bar"}),
        "",
        /^\/(?P<foo>[^\/]++)?(?:\/(?P<bar>[^\/]++))?$/,
        Set{"foo", "bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "foo"),
        ],
      },
      "variable in last position" => {
        ART::Route.new("/foo-{bar}"),
        "/foo-",
        /^\/foo\-(?P<bar>[^\/]++)$/,
        Set{"bar"},
        [
          ART::CompiledRoute::Token.new(:variable, "-", /[^\/]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),
        ],
      },
      "nested placeholders" => {
        ART::Route.new("/{static{var}static}"),
        "/{static",
        /^\/\{static(?P<var>[^\/]+)static\}$/,
        Set{"var"},
        [
          ART::CompiledRoute::Token.new(:text, "static}"),
          ART::CompiledRoute::Token.new(:variable, "", /[^\/]+/, "var"),
          ART::CompiledRoute::Token.new(:text, "/{static"),
        ],
      },
      "separator between variables" => {
        ART::Route.new("/{w}{x}{y}{z}.{_format}", {"z" => "default-z", "_format" => "html"}, {"y" => /(y|Y)/}),
        "",
        /^\/(?P<w>[^\/\.]+)(?P<x>[^\/\.]+)(?P<y>(?:y|Y))(?:(?P<z>[^\/\.]++)(?:\.(?P<_format>[^\/]++))?)?$/,
        Set{"w", "x", "y", "z", "_format"},
        [
          ART::CompiledRoute::Token.new(:variable, ".", /[^\/]++/, "_format"),
          ART::CompiledRoute::Token.new(:variable, "", /[^\/\.]++/, "z"),
          ART::CompiledRoute::Token.new(:variable, "", /(?:y|Y)/, "y"),
          ART::CompiledRoute::Token.new(:variable, "", /[^\/\.]+/, "x"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/\.]+/, "w"),
        ],
      },
      "with format" => {
        ART::Route.new("/foo/{bar}.{_format}"),
        "/foo",
        /^\/foo\/(?P<bar>[^\/\.]++)\.(?P<_format>[^\/]++)$/,
        Set{"bar", "_format"},
        [
          ART::CompiledRoute::Token.new(:variable, ".", /[^\/]++/, "_format"),
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/\.]++/, "bar"),
          ART::CompiledRoute::Token.new(:text, "/foo"),
        ],
      },
    }
  end

  def test_route_with_same_variable_twice : Nil
    expect_raises ART::Exception::InvalidArgument, "Route pattern '/{foo}/{foo}' cannot reference variable name 'foo' more than once." do
      ART::Route.new("/{foo}/{foo}").compile
    end
  end

  def test_route_with_fragment_as_path_parameter : Nil
    expect_raises ART::Exception::InvalidArgument, "Route pattern '/{_fragment}' cannot contain '_fragment' as a path parameter." do
      ART::Route.new("/{_fragment}").compile
    end
  end

  def test_route_with_too_long_parameter_name : Nil
    expect_raises ART::Exception::InvalidArgument, "Variable name 'abcdefghijklmnopqrstuvqxyz0123456789' cannot be longer than 32 characters in route pattern '/{abcdefghijklmnopqrstuvqxyz0123456789}'." do
      ART::Route.new("/{abcdefghijklmnopqrstuvqxyz0123456789}").compile
    end
  end

  @[DataProvider("names_starting_with_digit_provider")]
  def test_route_with_variable_name_starting_with_digit(name : String) : Nil
    expect_raises ART::Exception::InvalidArgument, "Variable name '#{name}' cannot start with a digit in route pattern '/{#{name}}'." do
      ART::Route.new("/{#{name}}").compile
    end
  end

  def names_starting_with_digit_provider : Tuple
    {
      {"09"},
      {"123"},
      {"1e2"},
    }
  end

  @[DataProvider("capture_group_provider")]
  def test_remove_capture_groups(expected : Regex, actual : Regex) : Nil
    ART::Route.new("/{foo}", requirements: {"foo" => actual}).compile.regex.should eq expected
  end

  def capture_group_provider : Tuple
    {
      {
        /^\/(?P<foo>a(?:b|c)(?:d|e)f)$/,

        /a(b|c)(d|e)f/,
      },
      {
        /^\/(?P<foo>a\(b\)c)$/,
        /a\(b\)c/,
      },
      {
        /^\/(?P<foo>(?:b))$/,
        /(?:b)/,
      },
      {
        /^\/(?P<foo>(*F))$/,
        /(*F)/,
      },
      {
        /^\/(?P<foo>(?:(?:foo)))$/,
        /((foo))/,
      },
    }
  end

  @[DataProvider("compiler_host_data_provider")]
  def test_compile_host_data(
    route : ART::Route,
    prefix : String,
    regex : Regex,
    variables : Set(String),
    path_variables : Set(String),
    tokens : Array(ART::CompiledRoute::Token),
    host_regex : Regex,
    host_variables : Set(String),
    host_tokens : Array(ART::CompiledRoute::Token),
  ) : Nil
    compiled_route = route.compile
    compiled_route.static_prefix.should eq prefix
    compiled_route.regex.should eq regex
    compiled_route.variables.should eq variables
    compiled_route.path_variables.should eq path_variables
    compiled_route.tokens.should eq tokens
    compiled_route.host_regex.should eq host_regex
    compiled_route.host_variables.should eq host_variables
    compiled_route.host_tokens.should eq host_tokens
  end

  def compiler_host_data_provider : Hash
    {
      "static value" => {
        ART::Route.new("/hello", host: "www.example.com"),
        "/hello",
        /^\/hello$/,
        Set(String).new,
        Set(String).new,
        [
          ART::CompiledRoute::Token.new(:text, "/hello"),
        ],
        /^www\.example\.com$/i,
        Set(String).new,
        [
          ART::CompiledRoute::Token.new(:text, "www.example.com"),
        ],
      },
      "with variable" => {
        ART::Route.new("/hello/{name}", host: "www.example.{tld}"),
        "/hello",
        /^\/hello\/(?P<name>[^\/]++)$/,
        Set{"tld", "name"},
        Set{"name"},
        [
          ART::CompiledRoute::Token.new(:variable, "/", /[^\/]++/, "name"),
          ART::CompiledRoute::Token.new(:text, "/hello"),
        ],
        /^www\.example\.(?P<tld>[^\.]++)$/i,
        Set{"tld"},
        [
          ART::CompiledRoute::Token.new(:variable, ".", /[^\.]++/, "tld"),
          ART::CompiledRoute::Token.new(:text, "www.example"),
        ],
      },
      "variable at beginning and end" => {
        ART::Route.new("/hello", host: "{locale}.example.{tld}"),
        "/hello",
        /^\/hello$/,
        Set{"locale", "tld"},
        Set(String).new,
        [
          ART::CompiledRoute::Token.new(:text, "/hello"),
        ],
        /^(?P<locale>[^\.]++)\.example\.(?P<tld>[^\.]++)$/i,
        Set{"locale", "tld"},
        [
          ART::CompiledRoute::Token.new(:variable, ".", /[^\.]++/, "tld"),
          ART::CompiledRoute::Token.new(:text, ".example"),
          ART::CompiledRoute::Token.new(:variable, "", /[^\.]++/, "locale"),
        ],
      },
      "variable with a default value" => {
        ART::Route.new("/hello", {"locale" => "a", "tld" => "b"}, host: "{locale}.example.{tld}"),
        "/hello",
        /^\/hello$/,
        Set{"locale", "tld"},
        Set(String).new,
        [
          ART::CompiledRoute::Token.new(:text, "/hello"),
        ],
        /^(?P<locale>[^\.]++)\.example\.(?P<tld>[^\.]++)$/i,
        Set{"locale", "tld"},
        [
          ART::CompiledRoute::Token.new(:variable, ".", /[^\.]++/, "tld"),
          ART::CompiledRoute::Token.new(:text, ".example"),
          ART::CompiledRoute::Token.new(:variable, "", /[^\.]++/, "locale"),
        ],
      },
    }
  end
end
