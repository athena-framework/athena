require "../../spec_helper"

describe "Console bundle not registered", tags: "compiled" do
  it "runs without the Console component" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "../../../src/athena"
      require "../../../src/spec"

      class ExampleController < ATH::Controller
        @[ARTA::Get("/")]
        def index : String
          "OK"
        end
      end

      struct WithoutConsoleTest < ATH::Spec::APITestCase
        def test_request : Nil
          self.get("/").body.should eq %("OK")
        end
      end

      ASPEC.run_all

      raise "Expected the Console component to not be required" if {{ @top_level.has_constant? "ACON" }}
    CR
  end

  it "errors if ATH.run_console is used" do
    ASPEC::Methods.assert_compile_time_error %('ATH.run_console' requires the Console bundle. Add `require "athena-console/bundle"` to register it.), <<-'CR'
      require "../../../src/athena"
      require "athena-console"

      ATH.run_console
    CR
  end

  it "does not register the debug commands" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../../../src/athena"
      require "athena-console"
      require "athena-spec"

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["athena_framework_commands_debug_router"] == nil }}, "Expected the debug commands to not be registered")
        end
      end
    CR
  end
end
