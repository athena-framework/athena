require "./spec_helper"

struct RouteTest < ASPEC::TestCase
  def test_constructor : Nil
    route = ART::Route.new "/{foo}", {"foo" => "bar"}, {"foo" => /\d+/}, host: "{locale}.example.com"
    route.path.should eq "/{foo}"
    route.defaults.should eq({"foo" => "bar"})
    route.requirements.should eq({"foo" => /\d+/})
    route.host.should eq "{locale}.example.com"

    route = ART::Route.new "/", schemes: {"Https"}, methods: {"POST", "put"}
    route.schemes.should eq Set{"https"}
    route.methods.should eq Set{"POST", "PUT"}

    route = ART::Route.new "/", schemes: "Https", methods: "Post"
    route.schemes.should eq Set{"https"}
    route.methods.should eq Set{"POST"}

    route = ART::Route.new "/foo", host: /foo.com/
    route.host.should eq "foo.com"
    route.host = /bar.net/
    route.host.should eq "bar.net"
  end

  @[DataProvider("path_provider")]
  def test_path(path : String, expected : String) : Nil
    route = ART::Route.new("/{foo}").path = path
    route.path.should eq expected
  end

  def path_provider : Hash
    {
      "simple"                     => {"/{bar}", "/{bar}"},
      "adds missing /"             => {"bar", "/bar"},
      "defaults to /"              => {"", "/"},
      "strips leading /"           => {"//path", "/path"},
      "keeps !"                    => {"/path/{!foo}", "/path/{!foo}"},
      "strips inline requirements" => {"/path/{bar<w++>}", "/path/{bar}"},
      "strips inline defaults"     => {"/path/{foo?value}", "/path/{foo}"},
      "strips all inline settings" => {"/path/{!bar<\\d+>?value}", "/path/{!bar}"},
    }
  end

  def test_defaults : Nil
    route = ART::Route.new "/{foo}"
    route.defaults = {"foo" => "bar"}
    route.defaults.should eq({"foo" => "bar"})

    route.defaults = Hash(String, String).new
    route.defaults.should be_empty

    route.set_default "foo", "bar"
    route.default("foo").should eq "bar"

    route.set_default "foo2", "bar2"
    route.default("foo2").should eq "bar2"
    route.default("missing").should be_nil

    route.defaults = {"foo" => "foo"}
    route.add_defaults({"bar" => "bar"})
    route.defaults.should eq({"foo" => "foo", "bar" => "bar"})

    route.has_default?("foo").should be_true
    route.has_default?("missing").should be_false
  end

  def test_requirements : Nil
    route = ART::Route.new "/{foo}"
    route.requirements = {"foo" => /\d+/, "bar" => "foo"}
    route.requirements.should eq({"foo" => /\d+/, "bar" => /foo/})

    route.requirement("foo").should eq /\d+/
    route.requirement("missing").should be_nil

    # Removes ^|\A and $|\z from the pattern
    route.requirements = {"foo" => /^\d+$/, "bar" => /\A\d+\z/}
    route.requirements.should eq({"foo" => /\d+/, "bar" => /\d+/})

    route.has_requirement?("foo").should be_true
    route.has_requirement?("missing").should be_false

    route.requirements = Hash(String, Regex | String).new
    route.set_requirement "foo", "foo"
    route.set_requirement "bar", /bar/
    route.requirements.should eq({"foo" => /foo/, "bar" => /bar/})
  end

  def test_compile : Nil
    route = ART::Route.new "/{foo}"
    compiled_route = route.compile
    route.compile.should eq compiled_route
    route.set_requirement "foo", /\d+/
    route.compile.should_not eq compiled_route
  end

  @[DataProvider("inline_settings_provider")]
  def test_inline_defaults_and_requirements(expected : ART::Route, actual : ART::Route) : Nil
    expected.should eq actual
  end

  def inline_settings_provider : Tuple
    {
      {
        ART::Route.new("/foo/{bar}").set_default("bar", nil),
        ART::Route.new("/foo/{bar?}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_default("bar", "baz"),
        ART::Route.new("/foo/{bar?baz}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_default("bar", "baz<buz>"),
        ART::Route.new("/foo/{bar?baz<buz>}"),
      },
      {
        ART::Route.new("/foo/{!bar}").set_default("bar", "baz<buz>"),
        ART::Route.new("/foo/{!bar?baz<buz>}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_default("bar", "baz"),
        ART::Route.new("/foo/{bar?}", {"bar" => "baz"}),
      },

      {
        ART::Route.new("/foo/{bar}").set_requirement("bar", ".*"),
        ART::Route.new("/foo/{bar<.*>}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_requirement("bar", ">"),
        ART::Route.new("/foo/{bar<>>}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_requirement("bar", /\d+/),
        ART::Route.new("/foo/{bar<.*>}", requirements: {"bar" => /\d+/}),
      },
      {
        ART::Route.new("/foo/{bar}").set_requirement("bar", "[a-z]{2}"),
        ART::Route.new("/foo/{bar<[a-z]{2}>}"),
      },
      {
        ART::Route.new("/foo/{!bar}").set_requirement("bar", "\\d+"),
        ART::Route.new("/foo/{!bar<\\d+>}"),
      },

      {
        ART::Route.new("/foo/{bar}").set_default("bar", nil).set_requirement("bar", ".*"),
        ART::Route.new("/foo/{bar<.*>?}"),
      },
      {
        ART::Route.new("/foo/{bar}").set_default("bar", "<>").set_requirement("bar", ">"),
        ART::Route.new("/foo/{bar<>>?<>}"),
      },

      {
        ART::Route.new("/{foo}/{!bar}").set_default("bar", "<>").set_default("foo", "\\").set_requirement("bar", /\\/).set_requirement("foo", "."),
        ART::Route.new("/{foo<.>?\\}/{!bar<\\>?<>}"),
      },

      {
        ART::Route.new("/").set_default("bar", nil).host=("{bar}"),
        ART::Route.new("/").host=("{bar?}"),
      },
      {
        ART::Route.new("/").set_default("bar", "baz").host=("{bar}"),
        ART::Route.new("/").host=("{bar?baz}"),
      },
      {
        ART::Route.new("/").set_default("bar", "baz<buz>").host=("{bar}"),
        ART::Route.new("/").host=("{bar?baz<buz>}"),
      },
      {
        ART::Route.new("/").set_default("bar", nil).host=("{bar}"),
        ART::Route.new("/", {"bar" => "baz"}).host=("{bar?}"),
      },

      {
        ART::Route.new("/").set_requirement("bar", ".*").host=("{bar}"),
        ART::Route.new("/").host=("{bar<.*>}"),
      },
      {
        ART::Route.new("/").set_requirement("bar", ">").host=("{bar}"),
        ART::Route.new("/").host=("{bar<>>}"),
      },
      {
        ART::Route.new("/").set_requirement("bar", ".*").host=("{bar}"),
        ART::Route.new("/", requirements: {"bar" => /\d+/}).host=("{bar<.*>}"),
      },
      {
        ART::Route.new("/").set_requirement("bar", "[a-z]{2}").host=("{bar}"),
        ART::Route.new("/").host=("{bar<[a-z]{2}>}"),
      },

      {
        ART::Route.new("/").set_default("bar", nil).set_requirement("bar", ".*").host=("{bar}"),
        ART::Route.new("/").host=("{bar<.*>?}"),
      },
      {
        ART::Route.new("/").set_default("bar", "<>").set_requirement("bar", ">").host=("{bar}"),
        ART::Route.new("/").host=("{bar<>>?<>}"),
      },
    }
  end

  @[DataProvider("non_localized_routes_provider")]
  def test_locale_default_with_non_localized_routes(route : ART::Route) : Nil
    route.default("_locale").should_not eq "fr"
    route.set_default "_locale", "fr"
    route.default("_locale").should eq "fr"
  end

  @[DataProvider("localized_routes_provider")]
  def test_locale_default_with_localized_routes(route : ART::Route) : Nil
    expected = route.default("_locale").should_not be_nil
    expected.should_not eq "fr"
    route.set_default "_locale", "fr"
    route.default("_locale").should eq expected
  end

  @[DataProvider("non_localized_routes_provider")]
  def test_locale_requirement_with_non_localized_routes(route : ART::Route) : Nil
    route.requirement("_locale").should_not eq "fr"
    route.set_requirement "_locale", "fr"
    route.requirement("_locale").should eq /fr/
  end

  @[DataProvider("localized_routes_provider")]
  def test_locale_requirement_with_localized_routes(route : ART::Route) : Nil
    expected = route.requirement("_locale").should_not be_nil
    expected.should_not eq "fr"
    route.set_requirement "_locale", "fr"
    route.requirement("_locale").should eq expected
  end

  def non_localized_routes_provider : Tuple
    {
      {ART::Route.new("/foo")},
      {ART::Route.new("/foo").set_default("_locale", "en")},
      {ART::Route.new("/foo").set_default("_locale", "en").set_default("_canonical_route", "foo")},
      {ART::Route.new("/foo").set_default("_locale", "en").set_default("_canonical_route", "foo").set_requirement("_locale", "foobar")},
    }
  end

  def localized_routes_provider : Tuple
    {
      {ART::Route.new("/foo").set_default("_locale", "en").set_default("_canonical_route", "foo").set_requirement("_locale", "en")},
    }
  end
end
