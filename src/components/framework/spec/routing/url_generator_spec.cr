require "../spec_helper"

private def route_collection(route : ATH::ActionBase) : ART::RouteCollection
  routes = ART::Spec::MockRouteCollection.new
  routes.add route
  routes
end

private def generator(routes : ART::RouteCollection, params : Hash(String, String) = Hash(String, String).new, *, base_uri : URI? = nil) : ART::URLGeneratorInterface
  request = new_request

  params.each do |p, v|
    case p
    when "host" then request.headers["host"] = v
    end
  end

  ART::URLGenerator.new routes, request, base_uri
end

describe ART::URLGenerator do
  describe "#generate" do
    it "with no routes" do
      expect_raises KeyError, "Unknown route: 'foo'." do
        generator(route_collection(new_action)).generate "foo"
      end
    end

    it "invalid optional param" do
      action = new_action(
        path: "/test/:id",
        arguments: [
          ATH::Arguments::ArgumentMetadata(Int32).new("id", true, default: 1),
        ],
        constraints: {"id" => /^\d$/}
      )

      expect_raises ArgumentError, "Route argument 'id' for route 'test' must match '(?-imsx:^\\d$)', got '10'." do
        generator(route_collection(action)).generate("test", {"id" => 10})
      end
    end

    it "invalid required param" do
      action = new_action(
        path: "/test/:id",
        arguments: [
          ATH::Arguments::ArgumentMetadata(Int32).new("id", false),
        ],
        constraints: {"id" => /1|2/}
      )

      expect_raises ArgumentError, "Route argument 'id' for route 'test' must match '(?-imsx:1|2)', got '3'." do
        generator(route_collection(action)).generate("test", {"id" => 3})
      end
    end

    it "required and blank" do
      action = new_action(
        path: "/test/:slug",
        arguments: [
          ATH::Arguments::ArgumentMetadata(Int32).new("slug", false),
        ],
        constraints: {"slug" => /.+/}
      )

      expect_raises ArgumentError, "Route argument 'slug' for route 'test' must match '(?-imsx:.+)', got ''." do
        generator(route_collection(action)).generate("test", {"slug" => ""})
      end
    end

    it "removes trailing / from optional params" do
      action = new_action(
        path: "/category/:slug1/:slug2/:slug3",
        arguments: [
          ATH::Arguments::ArgumentMetadata(String).new("slug1", false),
          ATH::Arguments::ArgumentMetadata(String?).new("slug2", false, true),
          ATH::Arguments::ArgumentMetadata(String?).new("slug3", false, true),
        ],
      )

      generator(route_collection(action)).generate("test", {"slug1" => "foo"}).should eq "/category/foo"
    end

    it "ignores null optional params" do
      action = new_action(
        path: "/test/:default",
        arguments: [
          ATH::Arguments::ArgumentMetadata(Int32).new("default", true, default: 0),
        ],
      )

      generator(route_collection(action)).generate("test", {"default" => nil}).should eq "/test"
    end

    it "doesn't include query params that are the same as the default" do
      action = new_action(
        arguments: [
          ATH::Arguments::ArgumentMetadata(Int32).new("page", true, default: 1),
        ],
        params: [
          ATH::Params::QueryParam(Int32).new("page", true, default: 1),
        ] of ATH::Params::ParamInterface
      )

      generator(route_collection(action)).generate("test", {"page" => 2}).should eq "/test?page=2"
      generator(route_collection(action)).generate("test", {"page" => 1}).should eq "/test"
      generator(route_collection(action)).generate("test", {"page" => "1"}).should eq "/test"
      generator(route_collection(action)).generate("test").should eq "/test"
    end

    it "doesn't include array query params that are the same as the default" do
      action = new_action(
        arguments: [
          ATH::Arguments::ArgumentMetadata(Array(String)).new("array", true, default: ["foo", "bar"]),
        ],
        params: [
          ATH::Params::QueryParam(Array(String)).new("array", true, default: ["foo", "bar"]),
        ] of ATH::Params::ParamInterface
      )

      generator(route_collection(action)).generate("test", {"array" => ["bar", "foo"]}).should eq "/test?array=%5B%22bar%22%2C+%22foo%22%5D"
      generator(route_collection(action)).generate("test", {"array" => ["foo", "bar"]}).should eq "/test"
      generator(route_collection(action)).generate("test").should eq "/test"
    end

    it "with special route name" do
      generator(route_collection(new_action(name: "$péß^a|"))).generate("$péß^a|").should eq "/test"
    end

    it "with fragment" do
      generator(route_collection(new_action)).generate("test", {"_fragment" => "anchor"}).should eq "/test#anchor"
    end

    describe "absolute url" do
      it "with port 80" do
        generator(route_collection(new_action), {"host" => "localhost:80"}).generate("test", reference_type: :absolute_url).should eq "https://localhost/test"
      end

      it "with port 443" do
        generator(route_collection(new_action), {"host" => "localhost:443"}).generate("test", reference_type: :absolute_url).should eq "https://localhost/test"
      end

      it "with non 80/443 port" do
        generator(route_collection(new_action), {"host" => "localhost:1234"}).generate("test", reference_type: :absolute_url).should eq "https://localhost:1234/test"
      end

      it "when host does not include port" do
        generator(route_collection(new_action), {"host" => "crystal-lang.org"}).generate("test", reference_type: :absolute_url).should eq "https://crystal-lang.org/test"
      end

      it "extra params" do
        generator(route_collection(new_action), {"host" => "localhost:80"}).generate("test", {"foo" => "bar"}, :absolute_url).should eq "https://localhost/test?foo=bar"
      end

      it "falls back to absolute_path if host is empty" do
        generator(route_collection(new_action)).generate("test", reference_type: :absolute_url).should eq "/test"
      end

      it "uses base_uri parameter if provided" do
        generator(route_collection(new_action), base_uri: URI.parse "http://google.com").generate("test", reference_type: :absolute_url).should eq "http://google.com/test"
      end

      it "prioritizes the base_uri parameter" do
        generator(route_collection(new_action), {"host" => "crystal-lang.org"}, base_uri: URI.parse "https://google.com").generate("test", reference_type: :absolute_url).should eq "https://google.com/test"
      end

      it "appends path to base_uri" do
        generator(route_collection(new_action), base_uri: URI.parse "http://example.com/foo/").generate("test", reference_type: :absolute_url).should eq "http://example.com/foo/test"
        generator(route_collection(new_action), base_uri: URI.parse "https://example.com/foo").generate("test", reference_type: :absolute_url).should eq "https://example.com/foo/test"
      end
    end

    describe "absolute path" do
      it "no parameters" do
        generator(route_collection(new_action)).generate("test", reference_type: :absolute_path).should eq "/test"
      end

      it "with parameters" do
        action = new_action(
          path: "/test/:id",
          arguments: [
            ATH::Arguments::ArgumentMetadata(Int32).new("id", false),
          ]
        )

        generator(route_collection(action)).generate("test", {"id" => 12}, :absolute_path).should eq "/test/12"
      end

      it "with nilable value" do
        action = new_action(
          path: "/test/:id",
          arguments: [
            ATH::Arguments::ArgumentMetadata(Int32?).new("id", false, is_nilable: true),
          ]
        )

        # Should remove the trailing /
        generator(route_collection(action)).generate("test", reference_type: :absolute_path).should eq "/test"
      end

      it "with no default value required not provided" do
        action = new_action(
          path: "/test/:id",
          arguments: [
            ATH::Arguments::ArgumentMetadata(Int32).new("id", false),
          ]
        )

        expect_raises ArgumentError, "Route argument 'id' is not nilable and was not provided nor has a default value." do
          generator(route_collection(action)).generate("test", reference_type: :absolute_path)
        end
      end

      it "with no default value required nil provided" do
        action = new_action(
          path: "/test/:id",
          arguments: [
            ATH::Arguments::ArgumentMetadata(Int32).new("id", false),
          ]
        )

        expect_raises ArgumentError, "Route argument 'id' is not nilable." do
          generator(route_collection(action)).generate("test", {"id" => nil}, :absolute_path)
        end
      end

      it "with default value" do
        action = new_action(
          path: "/test/:id",
          arguments: [
            ATH::Arguments::ArgumentMetadata(Int32).new("id", true, default: 0),
          ]
        )

        generator(route_collection(action)).generate("test", reference_type: :absolute_path).should eq "/test/0"
      end

      it "not passed param with default value in between" do
        action = new_action(
          path: "/:slug/:page",
          arguments: [
            ATH::Arguments::ArgumentMetadata(String).new("slug", true, default: "index"),
            ATH::Arguments::ArgumentMetadata(Int32).new("page", true, default: 0),
          ]
        )

        # Should use the default for slug, but not page
        generator(route_collection(action)).generate("test", {"page" => 1}, :absolute_path).should eq "/index/1"
      end

      pending "it doesn't include default values in generated path" do
        action = new_action(
          path: "/:slug/:page",
          arguments: [
            ATH::Arguments::ArgumentMetadata(String).new("slug", true, default: "index"),
            ATH::Arguments::ArgumentMetadata(Int32).new("page", true, default: 0),
          ]
        )

        # Resolves to `/` if no params are passed given it would just use the defaults
        generator(route_collection(action)).generate("test", reference_type: :absolute_path).should eq "/"
      end

      it "includes defaults if there is a non variable segments after" do
        action = new_action(
          path: "/:slug/:page/foo",
          arguments: [
            ATH::Arguments::ArgumentMetadata(String).new("slug", true, default: "index"),
            ATH::Arguments::ArgumentMetadata(Int32).new("page", true, default: 0),
          ]
        )

        generator(route_collection(action)).generate("test", reference_type: :absolute_path).should eq "/index/0/foo"
      end

      it "extra params" do
        generator(route_collection(new_action)).generate("test", {"foo" => "bar"}).should eq "/test?foo=bar"
      end

      it "null extra param" do
        generator(route_collection(new_action)).generate("test", {"foo" => nil}).should eq "/test"
      end

      it "ignores host header" do
        generator(route_collection(new_action), {"host" => "localhost"}).generate("test", {"foo" => nil}).should eq "/test"
      end

      it "ignores base_uri parameter" do
        generator(route_collection(new_action), base_uri: URI.parse "https://crystal-lang.org").generate("test", {"foo" => nil}).should eq "/test"
      end

      it "appends path from base_uri parameter" do
        generator(route_collection(new_action), base_uri: URI.parse "http://example.com/foo/").generate("test", {"foo" => nil}).should eq "/foo/test"
      end
    end

    describe "network path" do
      it "falls back to absolute_path if no hostname" do
        action = new_action(
          path: "/:name",
          arguments: [
            ATH::Arguments::ArgumentMetadata(String).new("name", false),
          ],
        )

        generator(route_collection(action)).generate("test", {"name" => "George"}, :network_path).should eq "/George"
      end

      it "utilizes host header" do
        action = new_action(
          path: "/:name",
          arguments: [
            ATH::Arguments::ArgumentMetadata(String).new("name", false),
          ],
        )

        generator(route_collection(action), {"host" => "localhost"}).generate("test", {"name" => "George", "query" => "string"}, :network_path).should eq "//localhost/George?query=string"
      end

      it "uses base_uri parameter if defined" do
        generator(route_collection(new_action), {"host" => "localhost"}, base_uri: URI.parse "https://crystal-lang.org").generate("test", {"foo" => nil}, :network_path).should eq "//crystal-lang.org/test"
      end

      it "appends path from base_uri parameter" do
        generator(route_collection(new_action), base_uri: URI.parse "http://example.com/foo/").generate("test", {"foo" => nil}, :network_path).should eq "//example.com/foo/test"
      end
    end
  end
end
