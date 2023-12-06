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

      it "errors if a configuration value has the incorrect type" do
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

      it "errors if there is a collection type mismatch" do
        assert_error "Expected configuration value 'test.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [] of String
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array" do
        assert_error "Expected configuration value 'test.foo[0]' to be a 'Int32', but got 'UInt64'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [10_u64] of Int32
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_error "Encountered unexpected property 'test.name' with value '\"Fred\"'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property id : Int32
          end

          ADI.configure({
            test: {
              id: 10,
              name: "Fred"
            }
          })
        CR
      end

      it "errors if an array does not specify its type" do
        assert_error "Array configuration value 'test.foo' must specify its type: [10_u64] of Int32", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            property foo : Array(Int32)
          end

          ADI.configure({
            test: {
              foo: [10_u64]
            }
          })
        CR
      end
    end

    describe "nested level" do
      it "errors if a configuration value has the incorrect type" do
        assert_error "Required configuration property 'test.sub_config.defaults.id : Int32' must be provided.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property name : String
                property id : Int32
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  name: "Fred"
                }
              }
            }
          })
        CR
      end

      it "errors if there is a collection type mismatch" do
        assert_error "Expected configuration value 'test.sub_config.defaults.foo' to be a 'Array(Int32)', but got 'Array(String)'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [] of String
                }
              }
            }
          })
        CR
      end

      it "errors if there is a type mismatch within an array" do
        assert_error "Expected configuration value 'test.sub_config.defaults.foo[1]' to be a 'Int32', but got 'UInt64'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [1, 10_u64] of Int32
                }
              }
            }
          })
        CR
      end

      it "errors if a configuration value not found in the schema is encountered" do
        assert_error "Encountered unexpected property 'test.sub_config.defaults.name' with value '\"Fred\"'.", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property id : Int32
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  id: 10,
                  name: "Fred"
                }
              }
            }
          })
        CR
      end

      it "errors if an array does not specify its type" do
        assert_error "Array configuration value 'test.sub_config.defaults.foo' must specify its type: [10_u64] of Int32", <<-CR
          @[ADI::RegisterExtension("test")]
          module FrameworkExtension
            include ADI::Extension

            module SubConfig
              include ADI::Extension

              module Defaults
                include ADI::Extension

                property foo : Array(Int32)
              end
            end
          end

          ADI.configure({
            test: {
              sub_config: {
                defaults: {
                  foo: [10_u64]
                }
              }
            }
          })
        CR
      end
    end

    it "errors if a configuration value has the incorrect type" do
      assert_error "Extension 'foo' is configured, but no extension with that name has been registered.", <<-CR
        ADI.configure({
          foo: {
            id: 1
          }
        })
      CR
    end

    it "resolves configuration values that point to constants" do
      ADI::CONFIG["blah"][:float].should eq 10
    end

    it "resolves configuration values that have nilable types to nil" do
      ADI::CONFIG["blah"][:nilable].should be_nil
    end

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
