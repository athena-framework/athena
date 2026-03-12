require "../spec_helper"

describe ADI::ServiceContainer::ProcessParameters, tags: "compiled" do
  it "populates parameter information of registered services" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register(_id: 123, public: true)]
      class SomeService
        def initialize(@id : Int32); end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            parameters = ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]
            id = parameters["id"]
          %}
          ASPEC.compile_time_assert(\{{ parameters.size == 1 }}, "Expected parameters size to be 1")
          ASPEC.compile_time_assert(\{{ id["declaration"].stringify == "id : Int32" }}, "Expected declaration to be id : Int32")
          ASPEC.compile_time_assert(\{{ id["name"] == "id" }}, "Expected name to be id")
          ASPEC.compile_time_assert(\{{ id["internal_name"] == "id" }}, "Expected internal_name to be id")
          ASPEC.compile_time_assert(\{{ id["idx"] == 0 }}, "Expected idx to be 0")
          ASPEC.compile_time_assert(\{{ id["restriction"].stringify == "Int32" }}, "Expected restriction to be Int32")
          ASPEC.compile_time_assert(\{{ id["resolved_restriction"].stringify == "Int32" }}, "Expected resolved_restriction to be Int32")
          ASPEC.compile_time_assert(\{{ id["default_value"].nil? }}, "Expected default_value to be nil")
          ASPEC.compile_time_assert(\{{ id["value"] == 123 }}, "Expected value to be 123")
        end
      end
    CR
  end

  it "does not override value of manually wired up parameters" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      class SomeService
        def initialize(@id : Int32); end
      end

      module MyExtension
        macro included
          macro finished
            {% verbatim do %}
              {%
                SERVICE_HASH["some_service"] = {
                  class: SomeService,
                  public: true,
                  parameters: {
                    id: {value: 999}
                  }
                }
              %}
            {% end %}
          end
        end
      end

      ADI.add_compiler_pass MyExtension, :before_optimization, 1028
      ADI::ServiceContainer.new

      macro finished
        macro finished
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"] == 999 }}, "Expected value to be 999")
        end
      end
    CR
  end

  it "does not override value of manually wired up parameters with default value" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      class SomeService
        def initialize(@id : Int32 = 123); end
      end

      module MyExtension
        macro included
          macro finished
            {% verbatim do %}
              {%
                SERVICE_HASH["some_service"] = {
                  class: SomeService,
                  public: true,
                  parameters: {
                    id: {value: 999}
                  }
                }
              %}
            {% end %}
          end
        end
      end

      ADI.add_compiler_pass MyExtension, :before_optimization, 1028
      ADI::ServiceContainer.new

      macro finished
        macro finished
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"] == 999 }}, "Expected value to be 999")
        end
      end
    CR
  end
end
