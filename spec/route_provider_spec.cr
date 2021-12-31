require "./spec_helper"
require "digest/md5"

struct RouteProviderTest < ASPEC::TestCase
  private COLLECTIONS = [
    ART::RouteCollection.new,
    self.default_collection,
    self.redirection_collection,
    self.root_prefix_collection,
    self.head_match_case_collection,
    self.group_optmized_collection,
    self.trailing_slash_collection,
    self.trailing_slash_collection,
    self.host_tree_collection,
    self.chunked_collection,
    self.demo_collection,
    self.suffix_collection,
    self.host_collection,
  ]

  def tear_down : Nil
    ART::RouteProvider.reset
  end

  {% begin %}
    {% for test_case in 0..12 %}
      def test_compile_{{test_case}} : Nil
        \{% begin %}
          ART::RouteProvider.compile COLLECTIONS[{{test_case}}]

          \{% data = read_file("#{__DIR__}/fixtures/route_provider/route_collection{{test_case}}.cr").split("####") %}

          ART::RouteProvider.match_host.should eq (\{{data[0].id}})
          ART::RouteProvider.static_routes.should eq (\{{data[1].id}})
          ART::RouteProvider.route_regexes.should eq (\{{data[2].id}})
          ART::RouteProvider.dynamic_routes.should eq (\{{data[3].id}})
          ART::RouteProvider.conditions.size.should eq (\{{data[4].id}})
        \{% end %}
      end
    {% end %}
  {% end %}

  def self.default_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "overridden", ART::Route.new "/overridden"

    # Defaults and requirements
    collection.add "foo", ART::Route.new "/foo/{bar}", {"def" => "test"}, {"bar" => /baz|athenaa/}

    # Method requirement
    collection.add "bar", ART::Route.new "/bar/{foo}", methods: {"GET", "head"}

    # GET also adds HEAD as valid
    collection.add "barhead", ART::Route.new "/barhead/{foo}", methods: {"GET"}

    # Simple
    collection.add "baz", ART::Route.new "/test/baz"

    # Simple with extension
    collection.add "baz2", ART::Route.new "/test/baz.html"

    # Trailing slash
    collection.add "baz3", ART::Route.new "/test/baz3/"

    # Trailing slash with variable
    collection.add "baz4", ART::Route.new "/test/{foo}/"

    # Trailing slash and method
    collection.add "baz5", ART::Route.new "/test/{foo}/", methods: "post"

    # Complex name
    collection.add "baz.baz6", ART::Route.new "/test/{foo}/", methods: "put"

    # Defaults without variable
    collection.add "foofoo", ART::Route.new "/foofoo", {"def" => "test"}

    # Pattern with quotes
    collection.add "quoter", ART::Route.new "/{quoter}", requirements: {"quoter" => /[']+/}

    # Space in pattern
    collection.add "space", ART::Route.new "/spa ce"

    # Prefixes
    collection1 = ART::RouteCollection.new
    collection1.add "overridden", ART::Route.new "/overridden1"
    collection1.add "foo1", ART::Route.new("/{foo}").methods=("PUT")
    collection1.add "bar1", ART::Route.new "/{bar}"
    collection1.add_prefix "/b\"b"
    collection2 = ART::RouteCollection.new
    collection2.add collection1
    collection2.add "overridden", ART::Route.new "/{var}", requirements: {"var" => /.*/}
    collection1 = ART::RouteCollection.new
    collection1.add "foo2", ART::Route.new "/{foo1}"
    collection1.add "bar2", ART::Route.new "/{bar1}"
    collection1.add_prefix "/b\"b"
    collection2.add collection1
    collection2.add_prefix "/a"
    collection.add collection2

    # Overridden through add (collection) and multiple sub-collections with no own prefix
    collection1 = ART::RouteCollection.new
    collection1.add "overridden2", ART::Route.new "/old"
    collection1.add "helloWorld", ART::Route.new "/hello/{who}", {"who" => "World!"}
    collection2 = ART::RouteCollection.new
    collection3 = ART::RouteCollection.new
    collection3.add "overridden2", ART::Route.new "/new"
    collection3.add "hey", ART::Route.new "/hey/"
    collection2.add collection3
    collection1.add collection2
    collection1.add_prefix "/multi"
    collection.add collection1

    # "dynamic" prefix"
    collection1 = ART::RouteCollection.new
    collection1.add "foo3", ART::Route.new "/{foo}"
    collection1.add "bar3", ART::Route.new "/{bar}"
    collection1.add_prefix "/b"
    collection1.add_prefix "{_locale}"
    collection.add collection1

    # Route between collections
    collection.add "ababa", ART::Route.new "/ababa"

    # Collection with static prefix but only one route"
    collection1 = ART::RouteCollection.new
    collection1.add "foo4", ART::Route.new "/{foo}"
    collection1.add_prefix "/aba"
    collection.add collection1

    # Prefix and host
    collection1 = ART::RouteCollection.new
    collection1.add "route1", ART::Route.new "/route1", host: "a.example.com"
    collection1.add "route2", ART::Route.new "/c2/route2", host: "a.example.com"
    collection1.add "route3", ART::Route.new "/c2/route3", host: "b.example.com"
    collection1.add "route4", ART::Route.new "/route4", host: "a.example.com"
    collection1.add "route5", ART::Route.new "/route5", host: "c.example.com"
    collection1.add "route6", ART::Route.new "/route6", host: nil
    collection.add collection1

    # Host and variables
    collection1 = ART::RouteCollection.new
    collection1.add "route11", ART::Route.new "/route11", host: "{var1}.example.com"
    collection1.add "route12", ART::Route.new "/route12", {"var1" => "val"}, host: "{var1}.example.com"
    collection1.add "route13", ART::Route.new "/route13/{name}", host: "{var1}.example.com"
    collection1.add "route14", ART::Route.new "/route14/{name}", {"var1" => "val"}, host: "{var1}.example.com"
    collection1.add "route15", ART::Route.new "/route15/{name}", host: "c.example.com"
    collection1.add "route16", ART::Route.new "/route16/{name}", {"var1" => "val"}, host: nil
    collection1.add "route17", ART::Route.new "/route17", host: nil
    collection.add collection1

    # Multiple sub-collections with a single route and prefix each
    collection1 = ART::RouteCollection.new
    collection1.add "a", ART::Route.new "/a..."
    collection2 = ART::RouteCollection.new
    collection2.add "b", ART::Route.new "/{var}"
    collection3 = ART::RouteCollection.new
    collection3.add "c", ART::Route.new "/{var}"
    collection3.add_prefix "/c"
    collection2.add collection3
    collection2.add_prefix "/b"
    collection1.add collection2
    collection1.add_prefix "/a"
    collection.add collection1

    collection
  end

  def self.redirection_collection : ART::RouteCollection
    collection = self.default_collection.dup

    collection.add "secure", ART::Route.new "/secure", schemes: "https"
    collection.add "nonsecure", ART::Route.new "/nonsecure", schemes: "http"

    collection
  end

  def self.root_prefix_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "static", ART::Route.new "/test"
    collection.add "dynamic", ART::Route.new "/{var}"
    collection.add_prefix "rootprefix"

    route = ART::Route.new "/with-condition"
    route.condition do |request|
      "GET" == request.method
    end

    collection.add "with-condition", route

    collection
  end

  def self.head_match_case_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "just_head", ART::Route.new "/just_head", methods: "HEAD"
    collection.add "head_and_get", ART::Route.new "/head_and_get", methods: {"HEAD", "GET"}
    collection.add "get_and_head", ART::Route.new "/get_and_head", methods: {"GET", "HEAD"}
    collection.add "post_and_head", ART::Route.new "/post_and_head", methods: {"POST", "HEAD"}
    collection.add "put_and_post", ART::Route.new "/put_and_post", methods: {"PUT", "POST"}
    collection.add "put_and_get_and_head", ART::Route.new "/put_and_post", methods: {"PUT", "GET", "HEAD"}

    collection
  end

  def self.group_optmized_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "a_first", ART::Route.new "/a/11"
    collection.add "a_second", ART::Route.new "/a/22"
    collection.add "a_third", ART::Route.new "/a/33"
    collection.add "a_wildcard", ART::Route.new "/{param}"
    collection.add "a_fourth", ART::Route.new "/a/44/"
    collection.add "a_fifth", ART::Route.new "/a/55/"
    collection.add "a_sixth", ART::Route.new "/a/66/"
    collection.add "nested_wildcard", ART::Route.new "/nested/{param}"

    collection.add "nested_a", ART::Route.new "/nested/group/a/"
    collection.add "nested_b", ART::Route.new "/nested/group/b/"
    collection.add "nested_c", ART::Route.new "/nested/group/c/"

    collection.add "slashed_a", ART::Route.new "/slashed/group/"
    collection.add "slashed_b", ART::Route.new "/slashed/group/b/"
    collection.add "slashed_c", ART::Route.new "/slashed/group/c/"

    collection
  end

  def self.trailing_slash_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "simple_trailing_slash_no_methods", ART::Route.new "/trailing/simple/no-methods/"
    collection.add "simple_trailing_slash_GET_method", ART::Route.new "/trailing/simple/get-method/", methods: "GET"
    collection.add "simple_trailing_slash_HEAD_method", ART::Route.new "/trailing/simple/head-method/", methods: "HEAD"
    collection.add "simple_trailing_slash_POST_method", ART::Route.new "/trailing/simple/post-method/", methods: "POST"
    collection.add "regex_trailing_slash_no_methods", ART::Route.new "/trailing/regex/no-methods/{param}/"
    collection.add "regex_trailing_slash_GET_method", ART::Route.new "/trailing/regex/get-method/{param}/", methods: "GET"
    collection.add "regex_trailing_slash_HEAD_method", ART::Route.new "/trailing/regex/head-method/{param}/", methods: "HEAD"
    collection.add "regex_trailing_slash_POST_method", ART::Route.new "/trailing/regex/post-method/{param}/", methods: "POST"

    collection.add "simple_not_trailing_slash_no_methods", ART::Route.new "/not-trailing/simple/no-methods"
    collection.add "simple_not_trailing_slash_GET_method", ART::Route.new "/not-trailing/simple/get-method", methods: "GET"
    collection.add "simple_not_trailing_slash_HEAD_method", ART::Route.new "/not-trailing/simple/head-method", methods: "HEAD"
    collection.add "simple_not_trailing_slash_POST_method", ART::Route.new "/not-trailing/simple/post-method", methods: "POST"
    collection.add "regex_not_trailing_slash_no_methods", ART::Route.new "/not-trailing/regex/no-methods/{param}"
    collection.add "regex_not_trailing_slash_GET_method", ART::Route.new "/not-trailing/regex/get-method/{param}", methods: "GET"
    collection.add "regex_not_trailing_slash_HEAD_method", ART::Route.new "/not-trailing/regex/head-method/{param}", methods: "HEAD"
    collection.add "regex_not_trailing_slash_POST_method", ART::Route.new "/not-trailing/regex/post-method/{param}", methods: "POST"

    collection
  end

  def self.host_tree_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "a", ART::Route.new "/", host: "{d}.e.c.b.a"
    collection.add "b", ART::Route.new "/", host: "d.c.b.a"
    collection.add "c", ART::Route.new "/", host: "{e}.e.c.b.a"

    collection
  end

  def self.chunked_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    1000.times do |idx|
      hash = Digest::MD5.hexdigest(idx.to_s)[0...6]
      collection.add "_#{idx}", ART::Route.new "/#{hash}/{a}/{b}/{c}/#{hash}"
    end

    collection
  end

  def self.demo_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "a", ART::Route.new "/admin/post/"
    collection.add "b", ART::Route.new "/admin/post/new"
    collection.add "c", ART::Route.new "/admin/post/{id}", requirements: {"id" => /\d+/}
    collection.add "d", ART::Route.new "/admin/post/{id}/edit", requirements: {"id" => /\d+/}
    collection.add "e", ART::Route.new "/admin/post/{id}/delete", requirements: {"id" => /\d+/}

    collection.add "f", ART::Route.new "/blog/"
    collection.add "g", ART::Route.new "/blog/rss.xml"
    collection.add "h", ART::Route.new "/blog/page/{page}", requirements: {"id" => /\d+/}
    collection.add "i", ART::Route.new "/blog/posts/{page}", requirements: {"id" => /\d+/}
    collection.add "j", ART::Route.new "/blog/comments/{id}/new", requirements: {"id" => /\d+/}

    collection.add "k", ART::Route.new "/blog/search"
    collection.add "l", ART::Route.new "/login"
    collection.add "m", ART::Route.new "/logout"
    collection.add_prefix "/{_locale}"
    collection.add "n", ART::Route.new "/{_locale}"
    collection.add_requirements({"_locale" => /en|fr/})
    collection.add_defaults({"_locale" => "en"})

    collection
  end

  def self.suffix_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "r1", ART::Route.new "abc{foo}/1"
    collection.add "r2", ART::Route.new "abc{foo}/2"

    collection.add "r10", ART::Route.new "abc{foo}/10"
    collection.add "r20", ART::Route.new "abc{foo}/20"
    collection.add "r100", ART::Route.new "abc{foo}/100"
    collection.add "r200", ART::Route.new "abc{foo}/200"

    collection
  end

  def self.host_collection : ART::RouteCollection
    collection = ART::RouteCollection.new

    collection.add "r1", ART::Route.new "abc{foo}", host: "{foo}.example.com"
    collection.add "r2", ART::Route.new "abc{foo}", host: "{foo}.example.com"

    collection
  end
end
