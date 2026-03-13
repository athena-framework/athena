require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: <<-'CRYSTAL', postamble: <<-'CR'
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
  CRYSTAL
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
      assert_compile_time_error "Service 'some_service' is missing required 'class' property.", <<-'CR'
        SERVICE_HASH["some_service"] = {
          public: false,
        }
      CR
    end
  end

  it "applies defaults to missing properties" do
    ASPEC::Methods.assert_compiles <<-'CR'
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
                    public: true,
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
          \{%
            some_service = ADI::ServiceContainer::SERVICE_HASH["some_service"]
          %}
          ASPEC.compile_time_assert(\{{ some_service["class"] == SomeService }}, "Expected class to be SomeService")
          ASPEC.compile_time_assert(\{{ some_service["public"] == true }}, "Expected public to be true")
          ASPEC.compile_time_assert(\{{ some_service["calls"].size == 0 }}, "Expected calls to be empty")
          ASPEC.compile_time_assert(\{{ some_service["tags"].size == 0 }}, "Expected tags to be empty")
          ASPEC.compile_time_assert(\{{ some_service["generics"].size == 0 }}, "Expected generics to be empty")
          ASPEC.compile_time_assert(\{{ some_service["parameters"].size == 0 }}, "Expected parameters to be empty")
          ASPEC.compile_time_assert(\{{ some_service["shared"] == true }}, "Expected shared to be true")
          ASPEC.compile_time_assert(\{{ some_service["referenced_services"].size == 0 }}, "Expected referenced_services to be empty")
        end
      end
    CR
  end
end
