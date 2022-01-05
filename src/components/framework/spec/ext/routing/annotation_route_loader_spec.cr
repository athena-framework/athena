require "../../spec_helper"

private def assert_collection(code : String) : Nil
  input = IO::Memory.new <<-CR
    require "../../../src/athena"
    require "spec"
    
    private def assert_route(
      *,
      path : String = "/",
      name : String = "compile_controller_action",
      methods : Set(String) = Set{"GET"},
      defaults : Hash(String, String?) = Hash(String, String?).new,
      requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new,
      host : String? = nil,
      schemes : Set(String)? = nil,
      condition : ART::Route::Condition? = nil,
    ) : Nil
      route_collection = ATH::Routing::AnnotationRouteLoader.route_collection

      route_collection.size.should eq 1

      route_name, route = route_collection.first

      route_name.should eq name

      route.path.should eq path
      route.methods.should eq methods
      route.schemes.should eq schemes
      route.host.should eq host
      route.requirements.should eq requirements
      route.defaults.should eq(Hash(String, String?){"_controller" => "CompileController#action"}.merge!(defaults))

      if condition
        route.condition.should_not be_nil
      else
        route.condition.should be_nil
      end
    end
    #{code}
  CR

  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--stdin-filename", "#{__DIR__}/test.cr"], input: input.rewind, output: buffer, error: buffer)
  result.success?.should be_true, failure_message: buffer.to_s
  buffer.close
end

describe ATH::Routing::AnnotationRouteLoader, tags: "long_compiler", focus: true do
  describe ".route_collection" do
    it "simple route" do
      assert_collection <<-CODE
        class App::CompileController < Athena::Framework::Controller
          @[ARTA::Get(path: "/")]
          def action : Nil; end
        end

        assert_route name: "app_compile_controller_action", defaults: {"_controller" => "App::CompileController#action"}
      CODE
    end

    it "custom route name" do
      assert_collection <<-CODE
        class CompileController < Athena::Framework::Controller
          @[ARTA::Get("/", name: "action")]
          def action : Nil; end
        end

        assert_route name: "action"
      CODE
    end

    it "globals" do
      assert_collection <<-CODE
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
        class CompileController < Athena::Framework::Controller
          @[ARTA::Route("/child")]
          def action : Nil; end
        end

        assert_route(
          path: "/parent/child",
          methods: Set{"FOO"},
          condition: ART::Route::Condition.new { false },
          schemes: Set{"https", "ftp"},
          requirements: {"foo" => /bar/},
          defaults: {"foo" => "bar", "_controller" => "CompileController#action"}
        )
      CODE
    end

    describe "custom route methods" do
      it String do
        assert_collection <<-CODE
          class CompileController < Athena::Framework::Controller
            @[ARTA::Route("/", methods: "FOO")]
            def action : Nil; end
          end

          assert_route methods: Set{"FOO"}
        CODE
      end

      it Enumerable do
        assert_collection <<-CODE
          class CompileController < Athena::Framework::Controller
            @[ARTA::Route("/", methods: {"BAR"})]
            def action : Nil; end
          end

          assert_route methods: Set{"BAR"}
        CODE
      end
    end
  end
end
