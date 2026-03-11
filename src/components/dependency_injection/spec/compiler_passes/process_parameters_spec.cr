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
            unless parameters.size == 1
              raise "#{parameters}"
            end

            id = parameters["id"]
            unless id["declaration"].stringify == "id : Int32"
              raise "#{id}"
            end

            unless id["name"] == "id"
              raise "#{id}"
            end

            unless id["internal_name"] == "id"
              raise "#{id}"
            end

            unless id["idx"] == 0
              raise "#{id}"
            end

            unless id["restriction"].stringify == "Int32"
              raise "#{id}"
            end

            unless id["resolved_restriction"].stringify == "Int32"
              raise "#{id}"
            end

            unless id["default_value"].nil?
              raise "#{id}"
            end

            unless id["value"] == 123
              raise "#{id}"
            end
            %}
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
          \{%
            unless ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"] == 999
              raise ""
            end
          %}
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
          \{%
            unless ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"] == 999
              raise ""
            end
          %}
        end
      end
    CR
  end
end
