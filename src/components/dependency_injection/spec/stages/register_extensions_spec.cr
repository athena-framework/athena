require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::RegisterExtensions, focus: true do
  describe "compiler errors", tags: "compiler" do
    describe "root level" do
      it "populates CONFIG based on defaults/provided values" do
        ADI::CONFIG["blah"][:id].should eq 123
        ADI::CONFIG["blah"][:name].should eq "fred"
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_error "Required configuration property 'test.id : Int32' must be provided.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property id : Int32
            property name : String
          end

          ADI.configure({
            test: {
              name: "Fred"
            }
          })
        CR
      end

      # it "errors if a configuration value not found in the schema is encountered" do
      #   assert_error "Encountered unexpected key 'id' with value '\"Fred\"' within 'framework'.", <<-CR
      #     ADI.register_extension "framework", {
      #       root: {
      #         id : Int32,
      #       },
      #     }

      #     ADI.configure({
      #       framework: {
      #         id: 10,
      #         name: "Fred"
      #       }
      #     })
      #   CR
      # end
    end

    # describe "top-level values" do
    #   it "populates CONFIG based on defaults/provided values" do
    #     ADI::CONFIG["example"][:id].should eq 123
    #     ADI::CONFIG["example"][:name].should eq "fred"
    #   end

    #   it "errors if a non-nilable top-level schema property is not provided" do
    #     assert_error "Required configuration value 'framework.some_feature.some_key : String' must be provided.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           some_key : String,
    #         },
    #       }
    #     CR
    #   end

    #   it "errors if a configuration value not found in the schema is encountered" do
    #     assert_error "Encountered unexpected key 'bar' with value '\"foo\"' within 'framework.some_feature'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           some_key : String?,
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             bar: "foo"
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors if there is a type mismatch" do
    #     assert_error "Expected configuration value 'framework.some_feature.foo' to be a 'Int32', but got 'String'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           foo : Int32,
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             foo: "foo"
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors if there is a collection type mismatch" do
    #     assert_error "Expected configuration value 'framework.some_feature.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           foo : Array(Int32),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             foo: [] of String
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors if there is a type mismatch within an array" do
    #     assert_error "Expected configuration value 'framework.some_feature.foo[0]' to be a 'String', but got 'UInt64'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           foo : Array(String),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             foo: [10_u64] of String
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors if an array does not specify its type" do
    #     assert_error "Array configuration value 'framework.some_feature.foo' must specify its type.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           foo : Array(String),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             foo: [10_u64]
    #           }
    #         }
    #       })
    #     CR
    #   end
    # end

    # describe "named tuple configuration value" do
    #   it "errors if a non-nilable property is not provided" do
    #     assert_error "Configuration value 'framework.some_feature.some_thing' is missing required value for 'some_key' of type 'String'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           some_thing : NamedTuple(some_key: String, foo: Int32),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             some_thing: {foo: 10}
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors if there is a type mismatch" do
    #     assert_error "Expected configuration value 'framework.some_feature.some_thing.foo' to be a 'Int32', but got 'String'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           some_thing : NamedTuple(foo: Int32),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             some_thing: {foo: "foo"}
    #           }
    #         }
    #       })
    #     CR
    #   end

    #   it "errors on unexpected key" do
    #     assert_error "Expected configuration value 'framework.some_feature.some_thing' to be a 'NamedTuple(foo: Int32)', but encountered unexpected key 'bar' with value '\"foo\"'.", <<-CR
    #       ADI.register_extension "framework", {
    #         some_feature: {
    #           some_thing : NamedTuple(foo: Int32),
    #         },
    #       }

    #       ADI.configure({
    #         framework: {
    #           some_feature: {
    #             some_thing: {foo: 10, bar: "foo"}
    #           }
    #         }
    #       })
    #     CR
    #   end
    # end
  end
end
