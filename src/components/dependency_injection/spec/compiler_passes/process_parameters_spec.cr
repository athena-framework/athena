require "../spec_helper"

describe ADI::ServiceContainer::ProcessParameters, tags: "compiled" do
  it "populates parameter information of registered services" do
    ASPEC::Methods.assert_success <<-CR, codegen: true
      require "../spec_helper.cr"

      @[ADI::Register(_id: 123)]
      class SomeService
        def initialize(@id : Int32); end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"].size}}.should eq 1 }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["arg"].stringify}}.should eq "id : Int32" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["name"].stringify}}.should eq %("id") }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["internal_name"].stringify}}.should eq %("id") }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["idx"]}}.should eq 0 }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["restriction"].stringify}}.should eq "Int32" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["resolved_restriction"].stringify}}.should eq "Int32" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["default_value"]}}.should be_nil }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"].stringify}}.should eq "123" }
        end
      end
    CR
  end

  it "does not override value of manually wired up parameters" do
    ASPEC::Methods.assert_success <<-CR, codegen: true
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
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"]["id"]["value"].stringify}}.should eq "999" }
        end
      end
    CR
  end
end
