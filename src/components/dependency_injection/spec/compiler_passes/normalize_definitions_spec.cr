require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    module MySchema
      include ADI::Extension::Schema

      property id : Int32 = 10
    end

    class SomeService; end

    module MyExtension
      macro included
          macro finished
            {% verbatim do %}
              {%
                #{code}
              %}
            {% end %}
          end
        end
    end

    ADI.register_extension "test", MySchema
    ADI.add_compiler_pass MyExtension, :before_optimization, 1028
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::NormalizeDefinitions, tags: "compiled" do
  describe "compiler errors" do
    it "`class` is not provided" do
      assert_error "Service 'some_service' is missing required 'class' property.", <<-CR
        SERVICE_HASH["some_service"] = {
          public: false,
        }
      CR
    end
  end

  it "applies defaults to missing properties" do
    ASPEC::Methods.assert_success <<-CR, codegen: true
      require "../spec_helper.cr"
      module MySchema
        include ADI::Extension::Schema

        property id : Int32 = 10
      end

      class SomeService; end

      module MyExtension
        macro included
            macro finished
              {% verbatim do %}
                {%
                  SERVICE_HASH["some_service"] = {
                    class: SomeService,
                  }
                %}
              {% end %}
            end
          end
      end

      ADI.register_extension "test", MySchema
      ADI.add_compiler_pass MyExtension, :before_optimization, 1028
      ADI::ServiceContainer.new

      macro finished
        macro finished
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["class"].stringify}}.should eq "SomeService" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["public"]}}.should be_false }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["calls"].stringify}}.should eq "[]" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["tags"].stringify}}.should eq "{}" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["generics"].stringify}}.should eq "[]" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["parameters"].stringify}}.should eq "{}" }
          it { \\{{ADI::ServiceContainer::SERVICE_HASH["some_service"]["shared"]}}.should be_true }
        end
      end
    CR
  end
end
