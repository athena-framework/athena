require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: %(require "./spec_helper.cr")
end

describe AORM::Bundle, tags: "compiled" do
  it "provides the entity manager" do
    assert_compiles <<-'CR'
      @[ADI::Register(public: true)]
      class EntityManagerConsumer
        def initialize(@entity_manager : AORM::EntityManagerInterface); end
      end

      ADI.container.entity_manager_consumer

      macro finished
        macro finished
          \{%
             service = ADI::ServiceContainer::SERVICE_HASH["athena_orm_registry"]
          %}
          ASPEC.compile_time_assert(\{{ service["parameters"]["url"]["value"] == "mock://" }}, "Expected url to be mock://")
        end
      end
    CR
  end

  it "requires the url to be configured" do
    ASPEC::Methods.assert_compile_time_error "Required configuration property 'orm.url : String' must be provided.", <<-'CR', preamble: %(require "../spec_helper.cr"\nrequire "../../src/bundle")
      ADI.container
    CR
  end
end
