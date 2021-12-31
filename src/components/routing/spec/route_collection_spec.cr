require "./spec_helper"

struct RouteCollectionTest < ASPEC::TestCase
  def test_route_interactions : Nil
    collection = ART::RouteCollection.new
    route = ART::Route.new "/foo"
    collection.add "foo", route
    collection.routes.should eq({"foo" => route})
    collection["foo"].should be route
    collection["foo"]?.should be route

    collection["bar"]?.should be_nil

    expect_raises ART::Exception::RouteNotFound, "No route with the name 'bar' exists." do
      collection["bar"]
    end
  end

  def test_overridden_route : Nil
    collection = ART::RouteCollection.new
    route1 = ART::Route.new "/foo"
    route2 = ART::Route.new "/bar"

    collection.add "foo", route1
    collection.add "foo", route2

    collection["foo"].should be route2
  end

  def test_deep_overridden_route : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo"

    collection1 = ART::RouteCollection.new
    collection1.add "foo", ART::Route.new "/foo1"

    collection2 = ART::RouteCollection.new
    collection2.add "foo", ART::Route.new "/foo2"

    collection1.add collection2
    collection.add collection1

    collection1["foo"].path.should eq "/foo2"
    collection["foo"].path.should eq "/foo2"
  end

  def test_size : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo"

    collection1 = ART::RouteCollection.new
    collection1.add "bar", ART::Route.new "/bar"

    collection.add collection1

    collection.size.should eq 2
  end

  def test_add_collection : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", foo = ART::Route.new "/foo"

    collection1 = ART::RouteCollection.new
    collection1.add "bar", bar = ART::Route.new "/bar"

    collection2 = ART::RouteCollection.new
    collection2.add "baz", baz = ART::Route.new "/baz"

    collection1.add collection2
    collection.add collection1

    collection.routes.should eq({"foo" => foo, "bar" => bar, "baz" => baz})
  end

  def test_add_defaults : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/{placeholder}"

    collection1 = ART::RouteCollection.new
    collection1.add "bar", ART::Route.new "/{placeholder}", {"placeholder" => "default", "foo" => "bar"}, {"placeholder" => /.+/}
    collection.add collection1

    collection.add_defaults({"placeholder" => "new-default"})
    collection["foo"].defaults.should eq({"placeholder" => "new-default"})
    collection["bar"].defaults.should eq({"placeholder" => "new-default", "foo" => "bar"})
  end

  def test_add_requirements : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/{placeholder}"

    collection1 = ART::RouteCollection.new
    collection1.add "bar", ART::Route.new "/{placeholder}", {"placeholder" => "default", "foo" => "bar"}, {"placeholder" => /.+/}
    collection.add collection1

    collection.add_requirements({"placeholder" => /\d+/})
    collection["foo"].requirements.should eq({"placeholder" => /\d+/})
    collection["bar"].requirements.should eq({"placeholder" => /\d+/})
  end

  def test_add_prefix : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo"

    collection1 = ART::RouteCollection.new
    collection1.add "bar", ART::Route.new "/bar"

    collection.add collection1
    collection.add_prefix " / "

    collection["foo"].path.should eq "/foo"

    collection.add_prefix "/{admin}", {"admin" => "admin"}, {"admin" => /\d+/}

    collection["foo"].path.should eq "/{admin}/foo"
    collection["bar"].path.should eq "/{admin}/bar"
    collection["foo"].defaults.should eq({"admin" => "admin"})
    collection["bar"].defaults.should eq({"admin" => "admin"})
    collection["foo"].requirements.should eq({"admin" => /\d+/})
    collection["bar"].requirements.should eq({"admin" => /\d+/})

    collection.add_prefix "0"

    collection["foo"].path.should eq "/0/{admin}/foo"

    collection.add_prefix "/ /"

    collection["foo"].path.should eq "/ /0/{admin}/foo"
    collection["bar"].path.should eq "/ /0/{admin}/bar"
  end

  def test_add_prefix_overrides_requirements : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo.{_format}"
    collection.add "bar", ART::Route.new "/bar.{_format}", requirements: {"_format" => "json"}
    collection.add_prefix "/admin", requirements: {"_format" => "html"}

    collection["foo"].requirement("_format").should eq /html/
    collection["bar"].requirement("_format").should eq /html/
  end

  def test_unique_route_with_given_name : Nil
    collection1 = ART::RouteCollection.new
    collection1.add "foo", ART::Route.new "/old"
    collection2 = ART::RouteCollection.new
    collection3 = ART::RouteCollection.new
    collection3.add "foo", route = ART::Route.new "/new"

    collection2.add collection3
    collection1.add collection2

    collection1["foo"].should be route
    collection1.size.should eq 1
  end

  def test_remove : Nil
    collection1 = ART::RouteCollection.new
    collection1.add "foo", ART::Route.new "/foo"

    collection2 = ART::RouteCollection.new
    collection2.add "bar", bar = ART::Route.new "/bar"
    collection1.add collection2
    collection1.add "last", last = ART::Route.new "/last"

    collection1.remove "foo"
    collection1.routes.should eq({"bar" => bar, "last" => last})
    collection1.remove "bar", "last"
    collection1.routes.should be_empty
  end

  def test_set_host : Nil
    collection = ART::RouteCollection.new
    collection.add "a", a = ART::Route.new "/a"
    collection.add "b", b = ART::Route.new "/b", host: "{locale}.example.net"

    collection.set_host "{locale}.example.com"

    a.host.should eq "{locale}.example.com"
    b.host.should eq "{locale}.example.com"
  end

  def test_clone : Nil
    collection = ART::RouteCollection.new
    collection.add "a", ART::Route.new "/a"
    collection.add "b", ART::Route.new "/b", {"placeholder" => "default"}, {"placeholder" => /.+/}

    cloned_collection = collection.clone

    cloned_collection.size.should eq 2
    cloned_collection["a"].should eq collection["a"]
    cloned_collection["a"].should_not be collection["a"]
    cloned_collection["b"].should eq collection["b"]
    cloned_collection["b"].should_not be collection["b"]
  end

  def test_set_scheme : Nil
    collection = ART::RouteCollection.new
    collection.add "a", a = ART::Route.new "/a", schemes: "http"
    collection.add "b", b = ART::Route.new "/b"

    collection.schemes = {"http", "https"}

    a.schemes.should eq Set{"http", "https"}
    b.schemes.should eq Set{"http", "https"}
  end

  def test_set_scheme : Nil
    collection = ART::RouteCollection.new
    collection.add "a", a = ART::Route.new "/a", methods: {"get", "POST"}
    collection.add "b", b = ART::Route.new "/b"

    collection.methods = "put"

    a.methods.should eq Set{"PUT"}
    b.methods.should eq Set{"PUT"}
  end

  def test_add_name_prefix : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", foo = ART::Route.new "/foo"
    collection.add "bar", bar = ART::Route.new "/bar"
    collection.add "api_foo", api_foo = ART::Route.new "/api/foo"

    collection.add_name_prefix "api_"

    collection["api_foo"].should be foo
    collection["api_bar"].should be bar
    collection["api_api_foo"].should be api_foo
    collection["foo"]?.should be_nil
    collection["bar"]?.should be_nil
  end

  def test_add_name_prefix_canonical_route_name : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo", {"_canonical_route" => "foo"}
    collection.add "bar", ART::Route.new "/bar", {"_canonical_route" => "bar"}
    collection.add "api_foo", ART::Route.new "/api/foo", {"_canonical_route" => "api_foo"}

    collection.add_name_prefix "api_"

    collection["api_foo"].default("_canonical_route").should eq "api_foo"
    collection["api_bar"].default("_canonical_route").should eq "api_bar"
    collection["api_api_foo"].default("_canonical_route").should eq "api_api_foo"
  end

  def test_add_with_priority : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", foo = ART::Route.new("/foo"), 0
    collection.add "bar", bar = ART::Route.new("/bar"), 1
    collection.add "baz", baz = ART::Route.new "/baz"

    collection.routes.should eq({
      "bar" => bar,
      "foo" => foo,
      "baz" => baz,
    })

    collection2 = ART::RouteCollection.new
    collection2.add "foo2", foo2 = ART::Route.new("/foo"), 0
    collection2.add "bar2", bar2 = ART::Route.new("/bar"), 1
    collection2.add "baz2", baz2 = ART::Route.new "/baz"
    collection2.add collection

    collection2.routes.should eq({
      "bar2" => bar2,
      "bar"  => bar,
      "foo2" => foo2,
      "baz2" => baz2,
      "baz"  => baz,
      "foo"  => foo,
    })
  end

  def test_add_with_priority_and_prefix : Nil
    collection = ART::RouteCollection.new
    collection.add "foo", foo = ART::Route.new("/foo"), 0
    collection.add "bar", bar = ART::Route.new("/bar"), 1
    collection.add "baz", baz = ART::Route.new "/baz"

    collection.add_name_prefix "prefix_"

    collection.routes.should eq({
      "prefix_bar" => bar,
      "prefix_foo" => foo,
      "prefix_baz" => baz,
    })
  end
end
