require "../../spec_helper"

private def assert_route(
  route_collection : ART::RouteCollection,
  file : String = __FILE__,
  line : Int32 = __LINE__,
  **args
)
  route_collection.size.should eq 1

  self.assert_route route_collection.first, **args, file: file, line: line
end

private def assert_route(
  route : Tuple(String, ART::Route),
  *,
  path : String = "/",
  methods : Set(String) = Set{"GET"},
  defaults : Hash(String, String?) = Hash(String, String?).new,
  requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new,
  host : String? = nil,
  schemes : Set(String)? = nil,
  condition : ART::Route::Condition? = nil,
  name : String? = nil,
  file : String = __FILE__,
  line : Int32 = __LINE__
) : Nil
  route_name, route = route

  route_name.should eq(name), line: line, file: file if name

  route.path.should eq(path), line: line, file: file
  route.methods.should eq(methods), line: line, file: file
  route.schemes.should eq(schemes), line: line, file: file
  route.host.should eq(host), line: line, file: file
  route.requirements.should eq(requirements), line: line, file: file

  route_defaults = route.defaults.dup
  route_defaults.delete "_controller" unless defaults.has_key?("_controller")

  route_defaults.should eq(defaults), line: line, file: file

  if condition
    route.condition.should_not be_nil, line: line, file: file
  else
    route.condition.should be_nil, line: line, file: file
  end
end

class App::CompileController < ATH::Controller
  @[ARTA::Get(path: "/")]
  def action : Nil; end
end

class CompileController < ATH::Controller
  @[ARTA::Get("/", name: "action")]
  def action : Nil; end
end

@[ARTA::Route(
  path: "parent",
  locale: "de",
  format: "json",
  stateless: true,
  name: "parent",
  requirements: {"foo" => "bar"},
  defaults: {"foo" => "bar"},
  schemes: ["https", "ftp"],
  methods: ["foo"],
  condition: ART::Route::Condition.new { false },
  priority: 16,
)]
class GlobalsController < ATH::Controller
  @[ARTA::Route("/child")]
  def action : Nil; end
end

@[ARTA::Route(
  path: "prefix",
)]
class PrefixedController < ATH::Controller
  @[ARTA::Post("")]
  def empty : Nil; end

  @[ARTA::Post("/")]
  def slash : Nil; end

  @[ARTA::Get("{id}")]
  def empty_param(id : String) : Nil; end

  @[ARTA::Get("/{id}")]
  def slash_param(id : String) : Nil; end
end

@[ARTA::Route(
  schemes: ["BAR", "foo", "baz"],
  methods: ["foo", "baz", "bar"],
  requirements: {"foo" => "bar"},
  defaults: {"foo" => "bar"},
  stateless: false
)]
class GlobalsMerges < ATH::Controller
  @[ARTA::Route(
    path: "/",
    methods: ["bar", "biz"],
    schemes: ["foo", "biz"],
    requirements: {"biz" => "baz"},
    defaults: {"biz" => "baz"},
  )]
  def action : Nil; end
end

class CustomMethodsString < ATH::Controller
  @[ARTA::Route("/", methods: "FOO")]
  def action : Nil; end
end

class CustomMethodsArray < ATH::Controller
  @[ARTA::Route("/", methods: {"BAR"})]
  def action : Nil; end
end

class LocalizedAction < ATH::Controller
  @[ARTA::Get({"en" => "/USA", "de" => "/Germany"})]
  def action : Nil; end
end

@[ARTA::Route(path: "prefix")]
class LocalizedPrefixedAction < ATH::Controller
  @[ARTA::Get({"en" => "/USA", "de" => "/Germany"})]
  def action : Nil; end

  @[ARTA::Get(path: {"en" => "{id}/USA", "de" => "/{id}/Germany"})]
  def index(id : String) : Nil; end
end

@[ARTA::Route(path: {"en" => "/USA", "de" => "/Germany"})]
class LocalizedClass < ATH::Controller
  @[ARTA::Get("")]
  def action : Nil; end

  @[ARTA::Get("{id}")]
  def index(id : String) : Nil; end
end

@[ARTA::Route(path: {"en" => "/parent", "de" => "/parent"})]
class LocalizedClassAction < ATH::Controller
  @[ARTA::Get(path: {"en" => "/USA", "de" => "/Germany"})]
  def action : Nil; end

  @[ARTA::Get(path: {"en" => "{id}/USA", "de" => "/{id}/Germany"})]
  def index(id : String) : Nil; end
end

class DefaultArgs < ATH::Controller
  @[ARTA::Get("/{slug}")]
  def action(id : Int32, slug : String = "foo", blah : Bool = false) : Nil; end
end

class RouteDefaultHelpers < ATH::Controller
  @[ARTA::Get("/", stateless: false, locale: "de", format: "json")]
  def action : Nil; end
end

enum StringificationColor
  Red
  Green
  Blue
end

class StringificationController < ATH::Controller
  @[ARTA::Get("/color/{color}", requirements: {"color" => ART::Requirement::Enum(StringificationColor).new, "foo" => /foo/, "bar" => "bar"})]
  def get_color(color : StringificationColor) : StringificationColor
    color
  end
end

describe ATH::Routing::AnnotationRouteLoader do
  describe ".route_collection" do
    it "simple route" do
      assert_route(
        ATH::Routing::AnnotationRouteLoader.populate_collection(App::CompileController),
        name: "app_compile_controller_action",
        defaults: {"_controller" => "App::CompileController#action"}
      )
    end

    it "custom route name" do
      assert_route(
        ATH::Routing::AnnotationRouteLoader.populate_collection(CompileController),
        name: "action",
        defaults: {"_controller" => "CompileController#action"}
      )
    end

    it "applies defaults from method arguments to defaults" do
      assert_route(
        ATH::Routing::AnnotationRouteLoader.populate_collection(DefaultArgs),
        path: "/{slug}",
        defaults: {"slug" => "foo"}
      )
    end

    it "with helper default values" do
      assert_route(
        ATH::Routing::AnnotationRouteLoader.populate_collection(RouteDefaultHelpers),
        defaults: {"_stateless" => "false", "_locale" => "de", "_format" => "json"}
      )
    end

    it "with a stringable route requirement" do
      assert_route(
        ATH::Routing::AnnotationRouteLoader.populate_collection(StringificationController),
        path: "/color/{color}",
        requirements: {"color" => /red|green|blue/, "foo" => /foo/, "bar" => /bar/}
      )
    end

    describe "custom route methods" do
      it String do
        assert_route(
          ATH::Routing::AnnotationRouteLoader.populate_collection(CustomMethodsString),
          methods: Set{"FOO"}
        )
      end

      it Enumerable do
        assert_route(
          ATH::Routing::AnnotationRouteLoader.populate_collection(CustomMethodsArray),
          methods: Set{"BAR"}
        )
      end
    end

    describe "localized routes" do
      describe "only on a method" do
        it "without a prefix" do
          routes = ATH::Routing::AnnotationRouteLoader.populate_collection(LocalizedAction).routes.to_a

          routes.size.should eq 2

          route = routes[0]

          assert_route(
            route,
            name: "localized_action_action.en",
            path: "/USA",
            defaults: {"_locale" => "en", "_canonical_route" => "localized_action_action"},
            requirements: {"_locale" => /en/}
          )

          route = routes[1]

          assert_route(
            route,
            name: "localized_action_action.de",
            path: "/Germany",
            defaults: {"_locale" => "de", "_canonical_route" => "localized_action_action"},
            requirements: {"_locale" => /de/}
          )
        end

        it "with prefix" do
          routes = ATH::Routing::AnnotationRouteLoader.populate_collection(LocalizedPrefixedAction).routes.to_a

          routes.size.should eq 4

          route = routes[0]

          assert_route(
            route,
            name: "localized_prefixed_action_action.en",
            path: "/prefix/USA",
            defaults: {"_locale" => "en", "_canonical_route" => "localized_prefixed_action_action"},
            requirements: {"_locale" => /en/}
          )

          route = routes[1]

          assert_route(
            route,
            name: "localized_prefixed_action_action.de",
            path: "/prefix/Germany",
            defaults: {"_locale" => "de", "_canonical_route" => "localized_prefixed_action_action"},
            requirements: {"_locale" => /de/}
          )

          route = routes[2]

          assert_route(
            route,
            name: "localized_prefixed_action_index.en",
            path: "/prefix/{id}/USA",
            defaults: {"_locale" => "en", "_canonical_route" => "localized_prefixed_action_index"},
            requirements: {"_locale" => /en/}
          )

          route = routes[3]

          assert_route(
            route,
            name: "localized_prefixed_action_index.de",
            path: "/prefix/{id}/Germany",
            defaults: {"_locale" => "de", "_canonical_route" => "localized_prefixed_action_index"},
            requirements: {"_locale" => /de/}
          )
        end
      end

      it "only on the class" do
        routes = ATH::Routing::AnnotationRouteLoader.populate_collection(LocalizedClass).routes.to_a

        routes.size.should eq 4

        route = routes[0]

        assert_route(
          route,
          name: "localized_class_action.en",
          path: "/USA",
          defaults: {"_locale" => "en", "_canonical_route" => "localized_class_action"},
          requirements: {"_locale" => /en/}
        )

        route = routes[1]

        assert_route(
          route,
          name: "localized_class_action.de",
          path: "/Germany",
          defaults: {"_locale" => "de", "_canonical_route" => "localized_class_action"},
          requirements: {"_locale" => /de/}
        )

        route = routes[2]

        assert_route(
          route,
          name: "localized_class_index.en",
          path: "/USA/{id}",
          defaults: {"_locale" => "en", "_canonical_route" => "localized_class_index"},
          requirements: {"_locale" => /en/}
        )

        route = routes[3]

        assert_route(
          route,
          name: "localized_class_index.de",
          path: "/Germany/{id}",
          defaults: {"_locale" => "de", "_canonical_route" => "localized_class_index"},
          requirements: {"_locale" => /de/}
        )
      end

      it "on both class and action" do
        routes = ATH::Routing::AnnotationRouteLoader.populate_collection(LocalizedClassAction).routes.to_a

        routes.size.should eq 4

        route = routes[0]

        assert_route(
          route,
          name: "localized_class_action_action.en",
          path: "/parent/USA",
          defaults: {"_locale" => "en", "_canonical_route" => "localized_class_action_action"},
          requirements: {"_locale" => /en/}
        )

        route = routes[1]

        assert_route(
          route,
          name: "localized_class_action_action.de",
          path: "/parent/Germany",
          defaults: {"_locale" => "de", "_canonical_route" => "localized_class_action_action"},
          requirements: {"_locale" => /de/}
        )

        route = routes[2]

        assert_route(
          route,
          name: "localized_class_action_index.en",
          path: "/parent/{id}/USA",
          defaults: {"_locale" => "en", "_canonical_route" => "localized_class_action_index"},
          requirements: {"_locale" => /en/}
        )

        route = routes[3]

        assert_route(
          route,
          name: "localized_class_action_index.de",
          path: "/parent/{id}/Germany",
          defaults: {"_locale" => "de", "_canonical_route" => "localized_class_action_index"},
          requirements: {"_locale" => /de/}
        )
      end
    end

    describe "globals" do
      it "applies to child routes" do
        assert_route(
          ATH::Routing::AnnotationRouteLoader.populate_collection(GlobalsController),
          name: "parent_globals_controller_action",
          path: "/parent/child",
          methods: Set{"FOO"},
          condition: ART::Route::Condition.new { false },
          schemes: Set{"https", "ftp"},
          requirements: {"foo" => /bar/},
          defaults: {"foo" => "bar", "_locale" => "de", "_format" => "json", "_stateless" => "true"}
        )
      end

      it "merges methods and schemes with the child route" do
        assert_route(
          ATH::Routing::AnnotationRouteLoader.populate_collection(GlobalsMerges),
          path: "/",
          schemes: Set{"bar", "foo", "baz", "biz"},
          methods: Set{"FOO", "BAZ", "BAR", "BIZ"},
          requirements: {"foo" => /bar/, "biz" => /baz/},
          defaults: {"foo" => "bar", "biz" => "baz", "_stateless" => "false"}
        )
      end

      it "normalizes prefixed route paths" do
        routes = ATH::Routing::AnnotationRouteLoader.populate_collection(PrefixedController).routes.to_a

        routes.size.should eq 4

        route = routes[0]

        assert_route(
          route,
          name: "prefixed_controller_empty",
          path: "/prefix",
          methods: Set{"POST"}
        )

        route = routes[1]

        assert_route(
          route,
          name: "prefixed_controller_slash",
          path: "/prefix/",
          methods: Set{"POST"}
        )

        route = routes[2]

        assert_route(
          route,
          name: "prefixed_controller_empty_param",
          path: "/prefix/{id}",
        )

        route = routes[3]

        assert_route(
          route,
          name: "prefixed_controller_slash_param",
          path: "/prefix/{id}",
        )
      end
    end
  end
end
