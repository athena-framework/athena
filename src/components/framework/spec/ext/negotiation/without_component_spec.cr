require "../../spec_helper"

describe "Negotiation component not required", tags: "compiled" do
  it "runs without the Negotiation component" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "../../../src/athena"
      require "../../../src/spec"

      class ExampleController < ATH::Controller
        @[ARTA::Get("/")]
        def index : String
          "OK"
        end
      end

      struct WithoutNegotiationTest < ATH::Spec::APITestCase
        def test_request : Nil
          self.get("/").body.should eq %("OK")
        end
      end

      ASPEC.run_all

      raise "Expected the Negotiation component to not be required" if {{ @top_level.has_constant? "ANG" }}
    CR
  end

  it "errors if the format listener is enabled" do
    ASPEC::Methods.assert_compile_time_error "The format listener requires the Negotiation component. Add `athena-negotiation` to your `shard.yml` and `require \"athena-negotiation\"` to enable it.", <<-'CR'
      require "../../../src/athena"

      ATH.configure({
        framework: {
          format_listener: {
            enabled: true,
            rules:   [
              {priorities: ["json"]},
            ],
          },
        },
      })
    CR
  end
end
